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
describe('Dépenses — liste', () => {
  const category = 'liste-test';

  beforeAll(async () => {
    const { awa, groupId } = await setupGroup();
    for (const [label, date] of [
      ['A', '2026-11-01'],
      ['B', '2026-11-02'],
      ['C', '2026-11-03'],
    ]) {
      await post(groupId, awa.accessToken, {
        label,
        category,
        amount: 1000,
        payerId: awa.user.id,
        date,
        split: { type: 'equal', participantIds: [awa.user.id] },
      });
    }
  });

  const get = (groupId: string, token: string, qs: string) =>
    api.get(`/api/v1/groups/${groupId}/expenses?${qs}`).set(authHeader(token));

  it('liste du plus récent au plus ancien (200)', async () => {
    const { awa, groupId } = await setupGroup();
    const res = await get(groupId, awa.accessToken, `category=${category}`);

    expect(res.status).toBe(200);
    expect(res.body.total).toBe(3);
    expect(res.body.items.map((e: { label: string }) => e.label)).toEqual(['C', 'B', 'A']);
  });

  it('pagine les résultats', async () => {
    const { awa, groupId } = await setupGroup();
    const res = await get(groupId, awa.accessToken, `category=${category}&limit=2&page=2`);

    expect(res.status).toBe(200);
    expect(res.body.items).toHaveLength(1);
    expect(res.body.page).toBe(2);
  });

  it('filtre par période', async () => {
    const { awa, groupId } = await setupGroup();
    const res = await get(groupId, awa.accessToken, `category=${category}&from=2026-11-02&to=2026-11-03`);

    expect(res.body.total).toBe(2);
  });

  it('refuse une limite supérieure à 50 (422)', async () => {
    const { awa, groupId } = await setupGroup();
    const res = await get(groupId, awa.accessToken, 'limit=100');

    expect(res.status).toBe(422);
  });

  it('un membre ordinaire peut lire la liste (200)', async () => {
    const { binta, groupId } = await setupGroup();
    const res = await get(groupId, binta.accessToken, `category=${category}`);

    expect(res.status).toBe(200);
  });

  it('refuse sans authentification (401)', async () => {
    const { groupId } = await setupGroup();
    const res = await api.get(`/api/v1/groups/${groupId}/expenses`);

    expect(res.status).toBe(401);
  });
});