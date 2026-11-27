import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { api, authHeader, registerUser, startMemoryDb, stopMemoryDb } from './helpers';

async function createContext() {
  const awa = await registerUser({ displayName: 'Awa' });
  const binta = await registerUser({ displayName: 'Binta' });
  const cherif = await registerUser({ displayName: 'Chérif' });

  const group = await api
    .post('/api/v1/groups')
    .set(authHeader(awa.accessToken))
    .send({ name: 'Coloc Plateau', currency: 'XOF' });
  const groupId = group.body.id as string;

  for (const member of [binta, cherif]) {
    const invite = await api
      .post(`/api/v1/groups/${groupId}/invitations`)
      .set(authHeader(awa.accessToken));
    await api
      .post(`/api/v1/invitations/${invite.body.token}/accept`)
      .set(authHeader(member.accessToken));
  }
  return { awa, binta, cherif, groupId };
}

let context: Awaited<ReturnType<typeof createContext>>;

beforeAll(async () => {
  await startMemoryDb();
  context = await createContext();
});
afterAll(stopMemoryDb);

async function setupGroup() {
  return context;
}

function post(groupId: string, token: string, body: object) {
  return api.post(`/api/v1/groups/${groupId}/expenses`).set(authHeader(token)).send(body);
}

const base = { label: 'Courses', category: 'alimentation' };

describe('Dépenses — création', () => {
  it('partage égal avec reste : le reste va au premier nom alphabétique (201)', async () => {
    const { awa, binta, cherif, groupId } = await setupGroup();

    const res = await post(groupId, awa.accessToken, {
      ...base,
      amount: 10000,
      payerId: awa.user.id,
      split: { type: 'equal', participantIds: [cherif.user.id, awa.user.id, binta.user.id] },
    });

    expect(res.status).toBe(201);
    const byUser = Object.fromEntries(
      res.body.shares.map((s: { userId: string; amount: number }) => [s.userId, s.amount]),
    );
    expect(byUser[awa.user.id]).toBe(3334);
    expect(byUser[binta.user.id]).toBe(3333);
    expect(byUser[cherif.user.id]).toBe(3333);
    const total = res.body.shares.reduce((t: number, s: { amount: number }) => t + s.amount, 0);
    expect(total).toBe(10000);
  });

  it('partage personnalisé dont la somme égale le total (201)', async () => {
    const { awa, binta, groupId } = await setupGroup();

    const res = await post(groupId, awa.accessToken, {
      ...base,
      amount: 5000,
      payerId: awa.user.id,
      split: {
        type: 'custom',
        shares: [
          { userId: awa.user.id, amount: 3000 },
          { userId: binta.user.id, amount: 2000 },
        ],
      },
    });

    expect(res.status).toBe(201);
    expect(res.body.amount).toBe(5000);
    expect(res.body.shares).toHaveLength(2);
  });

  it('refuse une somme de parts différente du total (422)', async () => {
    const { awa, binta, groupId } = await setupGroup();

    const res = await post(groupId, awa.accessToken, {
      ...base,
      amount: 5000,
      payerId: awa.user.id,
      split: {
        type: 'custom',
        shares: [
          { userId: awa.user.id, amount: 3000 },
          { userId: binta.user.id, amount: 1000 },
        ],
      },
    });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('SHARES_MISMATCH');
  });

  it('refuse un montant décimal ou négatif (422)', async () => {
    const { awa, groupId } = await setupGroup();
    const split = { type: 'equal', participantIds: [awa.user.id] };

    const decimal = await post(groupId, awa.accessToken, {
      ...base, amount: 100.5, payerId: awa.user.id, split,
    });
    const negative = await post(groupId, awa.accessToken, {
      ...base, amount: -100, payerId: awa.user.id, split,
    });

    expect(decimal.status).toBe(422);
    expect(negative.status).toBe(422);
  });

  it('refuse un payeur hors du groupe (422)', async () => {
    const { awa, groupId } = await setupGroup();
    const outsider = await registerUser();

    const res = await post(groupId, awa.accessToken, {
      ...base,
      amount: 1000,
      payerId: outsider.user.id,
      split: { type: 'equal', participantIds: [awa.user.id] },
    });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('INVALID_PAYER');
  });

  it('refuse un participant hors du groupe (422)', async () => {
    const { awa, groupId } = await setupGroup();
    const outsider = await registerUser();

    const res = await post(groupId, awa.accessToken, {
      ...base,
      amount: 1000,
      payerId: awa.user.id,
      split: { type: 'equal', participantIds: [awa.user.id, outsider.user.id] },
    });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('INVALID_PARTICIPANT');
  });

  it('refuse un participant en double (422)', async () => {
    const { awa, groupId } = await setupGroup();

    const res = await post(groupId, awa.accessToken, {
      ...base,
      amount: 1000,
      payerId: awa.user.id,
      split: { type: 'equal', participantIds: [awa.user.id, awa.user.id] },
    });

    expect(res.status).toBe(422);
    expect(res.body.error.code).toBe('DUPLICATE_PARTICIPANT');
  });

  it('refuse une date dans le futur (422)', async () => {
    const { awa, groupId } = await setupGroup();

    const res = await post(groupId, awa.accessToken, {
      ...base,
      amount: 1000,
      payerId: awa.user.id,
      date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      split: { type: 'equal', participantIds: [awa.user.id] },
    });

    expect(res.status).toBe(422);
  });
});

describe('Dépenses — accès', () => {
  const body = (userId: string) => ({
    ...base,
    amount: 1000,
    payerId: userId,
    split: { type: 'equal', participantIds: [userId] },
  });

  it('refuse un non-membre (403)', async () => {
    const { awa, groupId } = await setupGroup();
    const outsider = await registerUser();

    const res = await post(groupId, outsider.accessToken, body(awa.user.id));
    expect(res.status).toBe(403);
  });

  it('refuse sans authentification (401)', async () => {
    const { awa, groupId } = await setupGroup();

    const res = await api.post(`/api/v1/groups/${groupId}/expenses`).send(body(awa.user.id));
    expect(res.status).toBe(401);
  });

  // Règle Q20 non tranchée : hypothèse actuelle = administrateur uniquement.
  it('refuse un membre ordinaire (403) tant que Q20 = admin seulement', async () => {
    const { binta, groupId } = await setupGroup();

    const res = await post(groupId, binta.accessToken, body(binta.user.id));
    expect(res.status).toBe(403);
  });
});