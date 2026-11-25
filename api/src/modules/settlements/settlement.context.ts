import mongoose, { Schema } from 'mongoose';
import { SettlementContext } from './settlement.service.js';
import { Settlement } from './settlement.model.js';
import { ExpenseAdapter } from './expense.adapter.js';

// Temporary shared-model adapter for the empty starter repository. Keep the field
// contract aligned with the group/expense modules when those are added.
const groupSchema = new Schema({ currencyCode: String, members: [{ userId: Schema.Types.ObjectId }] }, { strict: false });
const Group = mongoose.models.Group ?? mongoose.model('Group', groupSchema);
const Expense = ExpenseAdapter;
export const settlementContext: SettlementContext = {
  async assertGroupMember(groupId, userId) {
    const group = await Group.findById(groupId).lean() as any;
    if (!group) { const e = new Error('Groupe introuvable.') as Error & { status: number }; e.status = 404; throw e; }
    if (!group.members?.some((m: any) => String(m.userId ?? m) === userId)) { const e = new Error('Accès réservé aux membres du groupe.') as Error & { status: number }; e.status = 403; throw e; }
  },
  async getCurrency(groupId) { const group = await Group.findById(groupId).lean() as any; return group?.currencyCode ?? 'XOF'; },
  async getAllowedDebt(groupId, fromUserId, toUserId) {
    const expenses = await Expense.find({ groupId }).lean() as any[];
    const net = new Map<string, number>();
    for (const expense of expenses) {
      net.set(String(expense.payerId), (net.get(String(expense.payerId)) ?? 0) + expense.amount);
      for (const part of expense.participants ?? []) net.set(String(part.userId), (net.get(String(part.userId)) ?? 0) - part.shareAmount);
    }
    const existing = await Settlement.find({ groupId, status: { $in: ['pending', 'confirmed'] } }).lean() as any[];
    for (const s of existing) { net.set(String(s.fromUserId), (net.get(String(s.fromUserId)) ?? 0) + s.amount); net.set(String(s.toUserId), (net.get(String(s.toUserId)) ?? 0) - s.amount); }
    return Math.max(0, Math.min(-(net.get(fromUserId) ?? 0), net.get(toUserId) ?? 0));
  },
};
