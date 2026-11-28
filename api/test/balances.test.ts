import mongoose from 'mongoose';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { EXPENSES_COLLECTION, SETTLEMENTS_COLLECTION } from '../src/modules/balances/services/balance-sources';
import { computeExpenseShares, type ExpenseSplitInput } from '../src/modules/expenses/domain/expense-shares';
import { api, authHeader, registerUser, startMemoryDb, stopMemoryDb, type TestUser } from './helpers';
import { sum } from './money-helpers';

/**
 * Tests d'intégration des endpoints de lecture des soldes et suggestions.
 *
 * Les dépenses et règlements sont insérés directement dans leurs collections, selon le
 * contrat de stockage partagé : leurs endpoints d'écriture appartiennent aux membres 3 et 4.
 * Les parts sont calculées avec `computeExpenseShares`, comme le fera le service des dépenses.
 */

const oid = (id: string) => new mongoose.Types.ObjectId(id);
const db = () => mongoose.connection.db!;

interface Coloc {
  awa: TestUser;
  binta: TestUser;
  cherif: TestUser;
  groupId: string;
}

let coloc: Coloc;

async function createGroupWithMembers(admin: TestUser, others: TestUser[]) {
  const created = await api.post('/api/v1/groups').set(authHeader(admin.accessToken)).send({ name: 'Coloc', currency: 'XOF' });
  const groupId = created.body.id as string;
  for (const other of others) {
    const invite = await api.post(`/api/v1/groups/${groupId}/invitations`).set(authHeader(admin.accessToken));
    const accepted = await api.post(`/api/v1/invitations/${invite.body.token}/accept`).set(authHeader(other.accessToken));
    expect(accepted.status).toBe(200);
  }
  return groupId;
}

async function insertExpense(groupId: string, payer: TestUser, amount: number, split: ExpenseSplitInput) {
  const members = await api.get(`/api/v1/groups/${groupId}/members`).set(authHeader(payer.accessToken));
  const participants = computeExpenseShares({ amount, payerId: payer.user.id, split, members: members.body });
  await db()
    .collection(EXPENSES_COLLECTION)
    .insertOne({
      groupId: oid(groupId),
      label: 'Dépense de test',
      amount,
      payerId: oid(payer.user.id),
      participants: participants.map((p) => ({ userId: oid(p.userId), shareAmount: p.shareAmount })),
      category: 'alimentation',
      spentAt: new Date(),
    });
}

async function insertSettlement(groupId: string, from: TestUser, to: TestUser, amount: number, status: 'pending' | 'confirmed') {
  const inserted = await db()
    .collection(SETTLEMENTS_COLLECTION)
    .insertOne({
      groupId: oid(groupId),
      fromUserId: oid(from.user.id),
      toUserId: oid(to.user.id),
      amount,
      currencyCode: 'XOF',
      recordedBy: oid(from.user.id),
      status,
      createdAt: new Date(),
    });
  return inserted.insertedId;
}

function getBalances(groupId: string, user: TestUser) {
  return api.get(`/api/v1/groups/${groupId}/balances`).set(authHeader(user.accessToken));
}

function getSuggestions(groupId: string, user: TestUser) {
  return api.get(`/api/v1/groups/${groupId}/settlement-suggestions`).set(authHeader(user.accessToken));
}

function balanceOf(body: { balances: { userId: string; balance: number }[] }, user: TestUser) {
  return body.balances.find((b) => b.userId === user.user.id)?.balance;
}

beforeAll(async () => {
  await startMemoryDb();
  // Le groupe est créé une seule fois : la création/acceptation d'invitations est limitée en fréquence.
  const awa = await registerUser({ displayName: 'Awa' });
  const binta = await registerUser({ displayName: 'Binta' });
  const cherif = await registerUser({ displayName: 'Chérif' });
  const groupId = await createGroupWithMembers(awa, [cherif, binta]);
  coloc = { awa, binta, cherif, groupId };
});
afterAll(stopMemoryDb);
beforeEach(async () => {
  await db().collection(EXPENSES_COLLECTION).deleteMany({});
  await db().collection(SETTLEMENTS_COLLECTION).deleteMany({});
});

describe('GET /groups/:groupId/balances', () => {
  it('renvoie des soldes nuls pour un groupe sans opération', async () => {
    const res = await getBalances(coloc.groupId, coloc.binta);

    expect(res.status).toBe(200);
    expect(res.body.groupId).toBe(coloc.groupId);
    expect(res.body.currency).toBe('XOF');
    expect(res.body.balances).toEqual([
      { userId: coloc.awa.user.id, displayName: 'Awa', balance: 0, isMember: true },
      { userId: coloc.binta.user.id, displayName: 'Binta', balance: 0, isMember: true },
      { userId: coloc.cherif.user.id, displayName: 'Chérif', balance: 0, isMember: true },
    ]);
  });

  it('calcule l\'exemple du cahier : 10 000 XOF payés par Awa et partagés à trois', async () => {
    const { awa, binta, cherif, groupId } = coloc;
    await insertExpense(groupId, awa, 10_000, {
      mode: 'equal',
      participantIds: [cherif.user.id, binta.user.id, awa.user.id],
    });

    const res = await getBalances(groupId, cherif);
    expect(res.status).toBe(200);
    expect(balanceOf(res.body, awa)).toBe(6_666);
    expect(balanceOf(res.body, binta)).toBe(-3_333);
    expect(balanceOf(res.body, cherif)).toBe(-3_333);
    expect(sum(res.body.balances.map((b: { balance: number }) => b.balance))).toBe(0);
  });

  it('cumule plusieurs dépenses (égale et personnalisée) avec une somme nulle', async () => {
    const { awa, binta, cherif, groupId } = coloc;
    await insertExpense(groupId, awa, 10_000, {
      mode: 'equal',
      participantIds: [awa.user.id, binta.user.id, cherif.user.id],
    });
    await insertExpense(groupId, binta, 9_000, {
      mode: 'custom',
      shares: [
        { userId: awa.user.id, shareAmount: 2_000 },
        { userId: binta.user.id, shareAmount: 4_000 },
        { userId: cherif.user.id, shareAmount: 3_000 },
      ],
    });

    const res = await getBalances(groupId, awa);
    expect(balanceOf(res.body, awa)).toBe(4_666);
    expect(balanceOf(res.body, binta)).toBe(1_667);
    expect(balanceOf(res.body, cherif)).toBe(-6_333);
    expect(sum(res.body.balances.map((b: { balance: number }) => b.balance))).toBe(0);
  });

  it('ignore un règlement en attente puis applique le même règlement une fois confirmé', async () => {
    const { awa, binta, groupId } = coloc;
    await insertExpense(groupId, awa, 10_000, {
      mode: 'equal',
      participantIds: [awa.user.id, binta.user.id, coloc.cherif.user.id],
    });
    const settlementId = await insertSettlement(groupId, binta, awa, 2_000, 'pending');

    const pending = await getBalances(groupId, binta);
    expect(balanceOf(pending.body, binta)).toBe(-3_333);
    expect(balanceOf(pending.body, awa)).toBe(6_666);

    await db().collection(SETTLEMENTS_COLLECTION).updateOne({ _id: settlementId }, { $set: { status: 'confirmed' } });

    const confirmed = await getBalances(groupId, binta);
    expect(balanceOf(confirmed.body, binta)).toBe(-1_333);
    expect(balanceOf(confirmed.body, awa)).toBe(4_666);
    expect(sum(confirmed.body.balances.map((b: { balance: number }) => b.balance))).toBe(0);
  });

  it('refuse un calcul sur une dépense enregistrée incohérente (500 explicite)', async () => {
    await db()
      .collection(EXPENSES_COLLECTION)
      .insertOne({
        groupId: oid(coloc.groupId),
        amount: 10_000,
        payerId: oid(coloc.awa.user.id),
        participants: [{ userId: oid(coloc.awa.user.id), shareAmount: 9_000 }],
      });

    const res = await getBalances(coloc.groupId, coloc.awa);
    expect(res.status).toBe(500);
    expect(res.body.error.code).toBe('BALANCE_INTEGRITY_ERROR');
  });
});

describe('GET /groups/:groupId/settlement-suggestions', () => {
  it('propose des transferts qui soldent le groupe sans créer de règlement', async () => {
    const { awa, binta, cherif, groupId } = coloc;
    await insertExpense(groupId, awa, 10_000, {
      mode: 'equal',
      participantIds: [awa.user.id, binta.user.id, cherif.user.id],
    });

    const res = await getSuggestions(groupId, binta);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      groupId,
      currency: 'XOF',
      suggestions: [
        { fromUserId: binta.user.id, fromDisplayName: 'Binta', toUserId: awa.user.id, toDisplayName: 'Awa', amount: 3_333 },
        { fromUserId: cherif.user.id, fromDisplayName: 'Chérif', toUserId: awa.user.id, toDisplayName: 'Awa', amount: 3_333 },
      ],
    });

    // Lecture seule : aucun règlement n'a été écrit et une seconde lecture donne le même résultat.
    expect(await db().collection(SETTLEMENTS_COLLECTION).countDocuments({})).toBe(0);
    const again = await getSuggestions(groupId, binta);
    expect(again.body).toEqual(res.body);
  });

  it('tient compte d\'un règlement confirmé (règlement partiel)', async () => {
    const { awa, binta, cherif, groupId } = coloc;
    await insertExpense(groupId, awa, 10_000, {
      mode: 'equal',
      participantIds: [awa.user.id, binta.user.id, cherif.user.id],
    });
    await insertSettlement(groupId, binta, awa, 2_000, 'confirmed');

    const res = await getSuggestions(groupId, awa);
    expect(res.body.suggestions).toEqual([
      { fromUserId: cherif.user.id, fromDisplayName: 'Chérif', toUserId: awa.user.id, toDisplayName: 'Awa', amount: 3_333 },
      { fromUserId: binta.user.id, fromDisplayName: 'Binta', toUserId: awa.user.id, toDisplayName: 'Awa', amount: 1_333 },
    ]);
  });

  it('ne propose rien quand les comptes sont équilibrés', async () => {
    const res = await getSuggestions(coloc.groupId, coloc.cherif);
    expect(res.status).toBe(200);
    expect(res.body.suggestions).toEqual([]);
  });
});

describe('Accès aux soldes et suggestions', () => {
  it.each(['balances', 'settlement-suggestions'])('refuse un utilisateur non membre (403) sur /%s', async (path) => {
    const outsider = await registerUser({ displayName: 'Intrus' });
    // Un identifiant de membre passé par le client ne donne aucun droit.
    const res = await api
      .get(`/api/v1/groups/${coloc.groupId}/${path}`)
      .query({ userId: coloc.awa.user.id })
      .set(authHeader(outsider.accessToken));
    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe('FORBIDDEN');
  });

  it.each(['balances', 'settlement-suggestions'])('exige un jeton valide (401) sur /%s', async (path) => {
    const res = await api.get(`/api/v1/groups/${coloc.groupId}/${path}`);
    expect(res.status).toBe(401);
  });

  it('retourne 404 pour un groupe inexistant ou un identifiant invalide', async () => {
    const missing = await getBalances('64b7f0c2e2c2c2c2c2c2c2c2', coloc.awa);
    expect(missing.status).toBe(404);
    const invalid = await getSuggestions('pas-un-identifiant', coloc.awa);
    expect(invalid.status).toBe(404);
  });

  it('n\'expose aucune route pour enregistrer un solde envoyé par l\'application', async () => {
    const res = await api
      .post(`/api/v1/groups/${coloc.groupId}/balances`)
      .set(authHeader(coloc.awa.accessToken))
      .send({ userId: coloc.awa.user.id, balance: 1_000_000 });
    expect(res.status).toBe(404);
  });
});

describe('Membre retiré du groupe', () => {
  it('garde son solde visible (isMember: false) pour que la somme reste nulle', async () => {
    const admin = await registerUser({ displayName: 'Awa' });
    const diane = await registerUser({ displayName: 'Diane' });
    const groupId = await createGroupWithMembers(admin, [diane]);
    await insertExpense(groupId, admin, 5_000, {
      mode: 'equal',
      participantIds: [admin.user.id, diane.user.id],
    });

    const removed = await api.delete(`/api/v1/groups/${groupId}/members/${diane.user.id}`).set(authHeader(admin.accessToken));
    expect(removed.status).toBe(204);

    const res = await getBalances(groupId, admin);
    expect(res.body.balances).toEqual([
      { userId: admin.user.id, displayName: 'Awa', balance: 2_500, isMember: true },
      { userId: diane.user.id, displayName: 'Diane', balance: -2_500, isMember: false },
    ]);

    // L'ancien membre n'a plus accès au groupe.
    const forbidden = await getBalances(groupId, diane);
    expect(forbidden.status).toBe(403);
  });
});
