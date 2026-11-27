import mongoose from 'mongoose';
import { computeNetBalances } from '../../balances/domain/balance-calculator';
import { MongoBalanceSources } from '../../balances/services/balance-sources';
import { GroupService } from '../../groups/services/group.service';
import { conflict, forbidden, notFound, unprocessable } from '../../../shared/errors/app-error';
import { addXof } from '../../../shared/money/xof';
import { Settlement } from '../models/settlement.model';
import type { CreateSettlementInput, HistoryQuery } from '../validators/settlement.validator';

/** Pending records provisionally reserve the sender's debt and recipient's credit. */
export const PENDING_SETTLEMENTS_RESERVE_BALANCE = true;

export class SettlementService {
  constructor(private readonly groups = new GroupService(), private readonly balanceSources = new MongoBalanceSources()) {}

  private async groupAndMembers(groupId: string, actorId: string) {
    const [group, members] = await Promise.all([
      this.groups.getGroup(groupId, actorId), this.groups.listMembers(groupId, actorId),
    ]);
    return { group, members };
  }

  async create(groupId: string, actorId: string, input: CreateSettlementInput) {
    const { group, members } = await this.groupAndMembers(groupId, actorId);
    const memberIds = new Set(members.map((m) => m.userId));
    if (!memberIds.has(input.fromUserId) || !memberIds.has(input.toUserId)) {
      throw unprocessable('Le payeur et le destinataire doivent appartenir au groupe', 'SETTLEMENT_MEMBER_REQUIRED');
    }
    const [expenses, confirmed, pending] = await Promise.all([
      this.balanceSources.listExpenses(groupId), this.balanceSources.listConfirmedSettlements(groupId),
      PENDING_SETTLEMENTS_RESERVE_BALANCE
        ? Settlement.find({ groupId, status: 'pending' }).select('fromUserId toUserId amount').lean()
        : Promise.resolve([]),
    ]);
    const balances = computeNetBalances({ memberIds: [...memberIds], expenses, settlements: confirmed });
    const debtorBalance = balances.get(input.fromUserId) ?? 0;
    const creditorBalance = balances.get(input.toUserId) ?? 0;
    if (debtorBalance >= 0 || creditorBalance <= 0) {
      throw unprocessable('Aucune dette nette ne justifie ce règlement', 'NO_SETTLEMENT_DEBT');
    }
    let reservedOutgoing = 0;
    let reservedIncoming = 0;
    for (const row of pending) {
      if (String(row.fromUserId) === input.fromUserId) reservedOutgoing = addXof(reservedOutgoing, row.amount);
      if (String(row.toUserId) === input.toUserId) reservedIncoming = addXof(reservedIncoming, row.amount);
    }
    const maximum = Math.min(Math.max(0, -debtorBalance - reservedOutgoing), Math.max(0, creditorBalance - reservedIncoming));
    if (maximum <= 0 || input.amount > maximum) {
      throw unprocessable('Le montant dépasse la dette nette encore disponible', 'SETTLEMENT_AMOUNT_EXCEEDS_DEBT', [{ path: 'amount', maximum }]);
    }
    return Settlement.create({ groupId, fromUserId: input.fromUserId, toUserId: input.toUserId,
      amount: input.amount, currency: group.currency, recordedBy: actorId, status: 'pending' });
  }

  async confirm(groupId: string, settlementId: string, actorId: string) {
    await this.groups.getGroup(groupId, actorId);
    if (!mongoose.isValidObjectId(settlementId)) throw notFound('Règlement introuvable', 'SETTLEMENT_NOT_FOUND');
    const row = await Settlement.findOne({ _id: settlementId, groupId });
    if (!row) throw notFound('Règlement introuvable', 'SETTLEMENT_NOT_FOUND');
    if (String(row.toUserId) !== actorId) throw forbidden('Seul le destinataire peut confirmer ce règlement');
    if (row.status !== 'pending') throw conflict('Ce règlement a déjà été confirmé', 'SETTLEMENT_ALREADY_CONFIRMED');
    const updated = await Settlement.findOneAndUpdate(
      { _id: row._id, groupId, status: 'pending' },
      { $set: { status: 'confirmed', confirmedAt: new Date() } }, { new: true, runValidators: true },
    );
    if (!updated) throw conflict('Ce règlement a déjà été confirmé', 'SETTLEMENT_ALREADY_CONFIRMED');
    return updated;
  }

  async listSettlements(groupId: string, actorId: string, query: HistoryQuery) {
    await this.groups.getGroup(groupId, actorId);
    const filter: Record<string, unknown> = { groupId };
    if (query.memberId) {
      if (!mongoose.isValidObjectId(query.memberId)) throw unprocessable('Identifiant de membre invalide');
      filter.$or = [{ fromUserId: query.memberId }, { toUserId: query.memberId }];
    }
    if (query.from || query.to) filter.createdAt = { ...(query.from && { $gte: query.from }), ...(query.to && { $lte: query.to }) };
    const skip = (query.page - 1) * query.limit;
    const [items, total] = await Promise.all([
      Settlement.find(filter).sort({ createdAt: -1, _id: -1 }).skip(skip).limit(query.limit).lean(),
      Settlement.countDocuments(filter),
    ]);
    return { items, page: query.page, limit: query.limit, total, pages: Math.ceil(total / query.limit) };
  }

  async activity(groupId: string, actorId: string, query: HistoryQuery) {
    await this.groups.getGroup(groupId, actorId);
    const groupObjectId = new mongoose.Types.ObjectId(groupId);
    const conditions: Record<string, unknown>[] = [];
    if (query.type) conditions.push({ type: query.type });
    if (query.from || query.to) conditions.push({ occurredAt: { ...(query.from && { $gte: query.from }), ...(query.to && { $lte: query.to }) } });
    if (query.memberId) {
      if (!mongoose.isValidObjectId(query.memberId)) throw unprocessable('Identifiant de membre invalide');
      const memberId = new mongoose.Types.ObjectId(query.memberId);
      conditions.push({ $or: [
        { type: 'settlement', fromUserId: memberId }, { type: 'settlement', toUserId: memberId },
        { type: 'expense', payerId: memberId }, { type: 'expense', 'participants.userId': memberId },
      ] });
    }
    if (query.payerId) {
      if (!mongoose.isValidObjectId(query.payerId)) throw unprocessable('Identifiant de payeur invalide');
      conditions.push({ type: 'expense', payerId: new mongoose.Types.ObjectId(query.payerId) });
    }
    if (query.category) conditions.push({ type: 'expense', category: query.category });
    const skip = (query.page - 1) * query.limit;
    const [result] = await Settlement.collection.aggregate([
      { $match: { groupId: groupObjectId } },
      { $addFields: { type: { $literal: 'settlement' }, occurredAt: '$createdAt' } },
      { $unionWith: { coll: 'expenses', pipeline: [
        { $match: { groupId: groupObjectId } },
        { $addFields: { type: { $literal: 'expense' }, occurredAt: { $ifNull: ['$spentAt', '$createdAt'] } } },
      ] } },
      ...(conditions.length ? [{ $match: { $and: conditions } }] : []),
      { $sort: { occurredAt: -1, _id: -1 } },
      { $facet: {
        items: [{ $skip: skip }, { $limit: query.limit }, { $project: {
          _id: 1, type: 1, occurredAt: 1, createdAt: 1, title: 1, label: 1, amount: 1, currency: 1,
          fromUserId: 1, toUserId: 1, payerId: 1, participants: 1, category: 1, status: 1, confirmedAt: 1,
        } }],
        metadata: [{ $count: 'total' }],
      } },
    ]).toArray();
    const total = result?.metadata?.[0]?.total ?? 0;
    return { items: result?.items ?? [], page: query.page, limit: query.limit, total, pages: Math.ceil(total / query.limit) };
  }
}
