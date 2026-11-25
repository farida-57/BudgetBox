import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { api, authHeader, cleanDb, registerUser, startMemoryDb, stopMemoryDb, type TestUser } from './helpers';

beforeAll(startMemoryDb);
afterAll(stopMemoryDb);
beforeEach(cleanDb);

async function createGroup(token: string, name = 'Coloc Plateau') {
  return api.post('/api/v1/groups').set(authHeader(token)).send({ name, currency: 'XOF' });
}

describe('Groupes — CRUD et membres', () => {
  it('crée un groupe dont le créateur est admin (201)', async () => {
    const user = await registerUser();
    const res = await createGroup(user.accessToken);

    expect(res.status).toBe(201);
    expect(res.body.name).toBe('Coloc Plateau');
    expect(res.body.currency).toBe('XOF');
    expect(res.body.role).toBe('admin');
    expect(res.body.memberCount).toBe(1);
  });

  it('liste uniquement les groupes de l\'utilisateur', async () => {
    const user = await registerUser();
    const other = await registerUser();
    await createGroup(user.accessToken, 'Groupe A');
    await createGroup(other.accessToken, 'Groupe B');

    const res = await api.get('/api/v1/groups').set(authHeader(user.accessToken));
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].name).toBe('Groupe A');
  });

  it('refuse l\'accès à un non-membre (403)', async () => {
    const owner = await registerUser();
    const outsider = await registerUser();
    const created = await createGroup(owner.accessToken);
    const groupId = created.body.id;

    const res = await api.get(`/api/v1/groups/${groupId}`).set(authHeader(outsider.accessToken));
    expect(res.status).toBe(403);
  });

  it('retourne 404 pour un groupe inexistant', async () => {
    const user = await registerUser();
    const res = await api
      .get('/api/v1/groups/64b7f0c2e2c2c2c2c2c2c2c2')
      .set(authHeader(user.accessToken));
    expect(res.status).toBe(404);
  });

  it('refuse toute la collection sans authentification (401)', async () => {
    const res = await api.get('/api/v1/groups');
    expect(res.status).toBe(401);
  });
});

describe('Invitations — usage unique', () => {
  async function setupInvite() {
    const admin: TestUser = await registerUser({ displayName: 'Admin' });
    const member: TestUser = await registerUser({ displayName: 'Invité' });
    const group = await createGroup(admin.accessToken);
    const groupId = group.body.id;

    const invite = await api
      .post(`/api/v1/groups/${groupId}/invitations`)
      .set(authHeader(admin.accessToken));
    expect(invite.status).toBe(201);
    return { admin, member, groupId, token: invite.body.token as string };
  }

  it('permet à un utilisateur connecté d\'accepter une invitation (200)', async () => {
    const { member, groupId, token } = await setupInvite();

    const res = await api.post(`/api/v1/invitations/${token}/accept`).set(authHeader(member.accessToken));
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(groupId);
    expect(res.body.role).toBe('membre');
    expect(res.body.memberCount).toBe(2);
  });

  it('refuse un lien inconnu ou déjà utilisé (404)', async () => {
    const { member, token } = await setupInvite();

    const bad = await api.post('/api/v1/invitations/lien-faux/accept').set(authHeader(member.accessToken));
    expect(bad.status).toBe(404);

    await api.post(`/api/v1/invitations/${token}/accept`).set(authHeader(member.accessToken));
    const reuse = await api.post(`/api/v1/invitations/${token}/accept`).set(authHeader(member.accessToken));
    expect(reuse.status).toBe(404);
  });

  it('refuse une seconde adhésion du même utilisateur (409)', async () => {
    const { admin, member, groupId, token } = await setupInvite();

    await api.post(`/api/v1/invitations/${token}/accept`).set(authHeader(member.accessToken));

    const newInvite = await api
      .post(`/api/v1/groups/${groupId}/invitations`)
      .set(authHeader(admin.accessToken));
    const res = await api
      .post(`/api/v1/invitations/${newInvite.body.token}/accept`)
      .set(authHeader(member.accessToken));
    expect(res.status).toBe(409);
  });

  it('réserve la création d\'invitation à l\'admin (403 pour un membre)', async () => {
    const { member, groupId, token } = await setupInvite();
    await api.post(`/api/v1/invitations/${token}/accept`).set(authHeader(member.accessToken));

    const res = await api.post(`/api/v1/groups/${groupId}/invitations`).set(authHeader(member.accessToken));
    expect(res.status).toBe(403);
  });
});

describe('Membres — retrait', () => {
  it('liste les membres avec leurs rôles', async () => {
    const admin = await registerUser({ displayName: 'Admin' });
    const member = await registerUser({ displayName: 'Membre' });
    const group = await createGroup(admin.accessToken);
    const groupId = group.body.id;
    const invite = await api.post(`/api/v1/groups/${groupId}/invitations`).set(authHeader(admin.accessToken));
    await api.post(`/api/v1/invitations/${invite.body.token}/accept`).set(authHeader(member.accessToken));

    const res = await api.get(`/api/v1/groups/${groupId}/members`).set(authHeader(admin.accessToken));
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);
    const roles = Object.fromEntries(res.body.map((m: { displayName: string; role: string }) => [m.displayName, m.role]));
    expect(roles['Admin']).toBe('admin');
    expect(roles['Membre']).toBe('membre');
  });

  it('refuse de retirer le dernier administrateur (409)', async () => {
    const admin = await registerUser();
    const group = await createGroup(admin.accessToken);
    const groupId = group.body.id;

    const res = await api
      .delete(`/api/v1/groups/${groupId}/members/${admin.user.id}`)
      .set(authHeader(admin.accessToken));
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe('LAST_ADMIN');
  });

  it('retire un membre par l\'admin (204) puis le non-membre perd l\'accès', async () => {
    const admin = await registerUser();
    const member = await registerUser();
    const group = await createGroup(admin.accessToken);
    const groupId = group.body.id;
    const invite = await api.post(`/api/v1/groups/${groupId}/invitations`).set(authHeader(admin.accessToken));
    await api.post(`/api/v1/invitations/${invite.body.token}/accept`).set(authHeader(member.accessToken));

    const del = await api
      .delete(`/api/v1/groups/${groupId}/members/${member.user.id}`)
      .set(authHeader(admin.accessToken));
    expect(del.status).toBe(204);

    const res = await api.get(`/api/v1/groups/${groupId}`).set(authHeader(member.accessToken));
    expect(res.status).toBe(403);
  });
});
