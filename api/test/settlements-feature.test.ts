import mongoose from 'mongoose';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { Group } from '../src/modules/groups/models/group.model';
import { api, authHeader, registerUser, startMemoryDb, stopMemoryDb, type TestUser } from './helpers';

const db = () => mongoose.connection.db!;
const oid = (value: string) => new mongoose.Types.ObjectId(value);
let awa: TestUser;
let binta: TestUser;
let cherif: TestUser;
let groupId: string;

async function seedExpense() {
  await db().collection('expenses').insertOne({
    groupId: oid(groupId), label: 'Courses', category: 'alimentation', amount: 1_000,
    payerId: oid(awa.user.id), spentAt: new Date(),
    participants: [
      { userId: oid(awa.user.id), shareAmount: 500 },
      { userId: oid(binta.user.id), shareAmount: 500 },
    ],
  });
}

beforeAll(async () => {
  await startMemoryDb();
  awa = await registerUser({ displayName: 'Awa' });
  binta = await registerUser({ displayName: 'Binta' });
  cherif = await registerUser({ displayName: 'Chérif' });
});
afterAll(stopMemoryDb);
beforeEach(async () => {
  await Group.deleteMany({});
  await db().collection('expenses').deleteMany({});
  await db().collection('settlements').deleteMany({});
  const group = await Group.create({ name: 'Colocation', currency: 'XOF', createdBy: awa.user.id,
    members: [awa, binta, cherif].map((user, index) => ({ userId: user.user.id, role: index === 0 ? 'admin' : 'membre' })) });
  groupId = group._id.toString();
  await seedExpense();
});

describe('Règlements', () => {
  it('crée un règlement pending, le réserve, puis seul le destinataire peut le confirmer une fois', async () => {
    const created = await api.post(`/api/v1/groups/${groupId}/settlements`).set(authHeader(binta.accessToken))
      .send({ fromUserId: binta.user.id, toUserId: awa.user.id, amount: 300 });
    expect(created.status).toBe(201);
    expect(created.body.status).toBe('pending');
    expect(created.body.currency).toBe('XOF');
    expect(created.body.data).toBeUndefined();

    const excessAfterReservation = await api.post(`/api/v1/groups/${groupId}/settlements`).set(authHeader(binta.accessToken))
      .send({ fromUserId: binta.user.id, toUserId: awa.user.id, amount: 201 });
    expect(excessAfterReservation.status).toBe(422);
    expect(excessAfterReservation.body.error.code).toBe('SETTLEMENT_AMOUNT_EXCEEDS_DEBT');

    const denied = await api.post(`/api/v1/groups/${groupId}/settlements/${created.body._id}/confirm`).set(authHeader(binta.accessToken));
    expect(denied.status).toBe(403);
    const confirmed = await api.post(`/api/v1/groups/${groupId}/settlements/${created.body._id}/confirm`).set(authHeader(awa.accessToken));
    expect(confirmed.status).toBe(200);
    expect(confirmed.body.status).toBe('confirmed');
    const duplicate = await api.post(`/api/v1/groups/${groupId}/settlements/${created.body._id}/confirm`).set(authHeader(awa.accessToken));
    expect(duplicate.status).toBe(409);
  });

  it('refuse un montant décimal, un membre extérieur et un accès sans jeton', async () => {
    const decimal = await api.post(`/api/v1/groups/${groupId}/settlements`).set(authHeader(binta.accessToken))
      .send({ fromUserId: binta.user.id, toUserId: awa.user.id, amount: 10.5 });
    expect(decimal.status).toBe(422);
    const outsider = await api.post(`/api/v1/groups/${groupId}/settlements`).set(authHeader(cherif.accessToken))
      .send({ fromUserId: cherif.user.id, toUserId: awa.user.id, amount: 1 });
    expect(outsider.status).toBe(422);
    const unauthenticated = await api.get(`/api/v1/groups/${groupId}/activity`);
    expect(unauthenticated.status).toBe(401);
  });
});

describe('Historique de groupe', () => {
  it('mélange dépenses et règlements, filtre par type et applique pagination/contrôle membre', async () => {
    await api.post(`/api/v1/groups/${groupId}/settlements`).set(authHeader(binta.accessToken))
      .send({ fromUserId: binta.user.id, toUserId: awa.user.id, amount: 250 });
    const all = await api.get(`/api/v1/groups/${groupId}/activity?page=1&limit=1`).set(authHeader(awa.accessToken));
    expect(all.status).toBe(200);
    expect(all.body.total).toBe(2);
    expect(all.body.items).toHaveLength(1);
    expect(all.body.pages).toBe(2);

    const expenses = await api.get(`/api/v1/groups/${groupId}/activity?type=expense`).set(authHeader(awa.accessToken));
    expect(expenses.body.total).toBe(1);
    expect(expenses.body.items[0].type).toBe('expense');

    const outsider = await api.get(`/api/v1/groups/${groupId}/activity`).set(authHeader(cherif.accessToken));
    expect(outsider.status).toBe(200); // Chérif is a group member.
    const privateGroup = await Group.create({ name: 'Privé', currency: 'XOF', createdBy: awa.user.id, members: [{ userId: awa.user.id, role: 'admin' }] });
    const forbidden = await api.get(`/api/v1/groups/${privateGroup.id}/activity`).set(authHeader(binta.accessToken));
    expect(forbidden.status).toBe(403);
  });
});
