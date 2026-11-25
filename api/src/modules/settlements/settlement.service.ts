import mongoose from 'mongoose';
import { Settlement } from './settlement.model.js';
import { ExpenseAdapter } from './expense.adapter.js';

export class HttpError extends Error { constructor(public status: number, message: string) { super(message); } }
export interface SettlementContext {
  assertGroupMember(groupId: string, userId: string): Promise<void>;
  /** Return remaining net debt from authenticated user's perspective, including pending reservations. */
  getAllowedDebt(groupId: string, fromUserId: string, toUserId: string): Promise<number>;
  getCurrency(groupId: string): Promise<string>;
}
const validId = (id: string) => mongoose.isValidObjectId(id);

export class SettlementService {
  constructor(private context: SettlementContext) {}
  async create(groupId: string, actorId: string, fromUserId: string, toUserId: string, amount: number) {
    if (![groupId, actorId, fromUserId, toUserId].every(validId)) throw new HttpError(422, 'Identifiant invalide.');
    await this.context.assertGroupMember(groupId, actorId);
    if (fromUserId === toUserId || !Number.isSafeInteger(amount) || amount <= 0) throw new HttpError(422, 'Le payeur, le destinataire ou le montant est invalide.');
    await this.context.assertGroupMember(groupId, fromUserId);
    await this.context.assertGroupMember(groupId, toUserId);
    const limit = await this.context.getAllowedDebt(groupId, fromUserId, toUserId);
    if (!Number.isSafeInteger(limit) || amount > limit) throw new HttpError(422, 'Le montant dépasse la dette autorisée.');
    return Settlement.create({ groupId, fromUserId, toUserId, amount, recordedBy: actorId, currencyCode: await this.context.getCurrency(groupId), status: 'pending' });
  }
  async confirm(groupId: string, settlementId: string, actorId: string) {
    if (![groupId, actorId, settlementId].every(validId)) throw new HttpError(404, 'Règlement introuvable.');
    await this.context.assertGroupMember(groupId, actorId);
    const row = await Settlement.findOne({ _id: settlementId, groupId });
    if (!row) throw new HttpError(404, 'Règlement introuvable.');
    if (String(row.toUserId) !== actorId) throw new HttpError(403, 'Seul le destinataire peut confirmer ce règlement.');
    if (row.status !== 'pending') throw new HttpError(409, 'Ce règlement a déjà été confirmé.');
    // Atomic compare-and-set: concurrent confirmations cannot apply twice.
    const updated = await Settlement.findOneAndUpdate({ _id: row._id, status: 'pending' }, { $set: { status: 'confirmed', confirmedAt: new Date() } }, { new: true });
    if (!updated) throw new HttpError(409, 'Ce règlement a déjà été confirmé.');
    return updated;
  }
  async list(groupId: string, actorId: string, query: { page: number; limit: number; memberId?: string; from?: Date; to?: Date }) {
    if (!validId(groupId)) throw new HttpError(422, 'Identifiant de groupe invalide.');
    await this.context.assertGroupMember(groupId, actorId);
    const filter: Record<string, unknown> = { groupId };
    if (query.memberId) { if (!validId(query.memberId)) throw new HttpError(422, 'Membre invalide.'); filter.$or = [{ fromUserId: query.memberId }, { toUserId: query.memberId }]; }
    if (query.from || query.to) filter.createdAt = { ...(query.from && { $gte: query.from }), ...(query.to && { $lte: query.to }) };
    const [items, total] = await Promise.all([Settlement.find(filter).sort({ createdAt: -1, _id: -1 }).skip((query.page - 1) * query.limit).limit(query.limit).lean(), Settlement.countDocuments(filter)]);
    return { items, page: query.page, limit: query.limit, total, pages: Math.ceil(total / query.limit) };
  }
  async activity(groupId: string, actorId: string, query: { page: number; limit: number; memberId?: string; from?: Date; to?: Date; category?: string; payerId?: string; type?: 'expense' | 'settlement' }) {
    if (!validId(groupId)) throw new HttpError(422, 'Identifiant de groupe invalide.');
    await this.context.assertGroupMember(groupId, actorId);
    const dateFilter = { ...(query.from && { $gte: query.from }), ...(query.to && { $lte: query.to }) };
    const [settlements, expenses] = await Promise.all([
      query.type === 'expense' ? [] : Settlement.find({ groupId, ...(query.memberId && { $or: [{ fromUserId: query.memberId }, { toUserId: query.memberId }] }), ...(Object.keys(dateFilter).length && { createdAt: dateFilter }) }).lean(),
      query.type === 'settlement' ? [] : ExpenseAdapter.find({ groupId, ...(query.memberId && { $or: [{ payerId: query.memberId }, { 'participants.userId': query.memberId }] }), ...(query.payerId && { payerId: query.payerId }), ...(query.category && { category: query.category }), ...(Object.keys(dateFilter).length && { spentAt: dateFilter }) }).lean(),
    ]) as [any[], any[]];
    const items = [...settlements.map((row: any) => ({ ...row, type: 'settlement', occurredAt: row.createdAt })), ...expenses.map((row: any) => ({ ...row, type: 'expense', occurredAt: row.spentAt ?? row.createdAt }))].sort((a: any, b: any) => new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime());
    const start = (query.page - 1) * query.limit;
    return { items: items.slice(start, start + query.limit), page: query.page, limit: query.limit, total: items.length, pages: Math.ceil(items.length / query.limit) };
  }
}
