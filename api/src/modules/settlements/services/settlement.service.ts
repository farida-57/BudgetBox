import mongoose from 'mongoose';
import { conflict, forbidden, notFound } from '../../../shared/errors/app-error';
import { Group, type GroupDocument } from '../../groups/models/group.model';
import {
  SETTLEMENT_STATUSES,
  Settlement,
  type SettlementDocument,
  type SettlementStatus,
} from '../models/settlement.model';
import type { CreateSettlementInput } from '../validators/settlement.validator';
import { getPairwiseDebt } from './debt.provider';

async function findGroupOr404(groupId: string): Promise<GroupDocument> {
  if (!mongoose.isValidObjectId(groupId)) {
    throw notFound('Groupe introuvable', 'GROUP_NOT_FOUND');
  }
  const group = await Group.findById(groupId);
  if (!group) {
    throw notFound('Groupe introuvable', 'GROUP_NOT_FOUND');
  }
  return group;
}

function isMember(group: GroupDocument, userId: string): boolean {
  return group.members.some((m) => m.userId.toString() === userId);
}

function assertMember(group: GroupDocument, userId: string) {
  if (!isMember(group, userId)) {
    throw forbidden("Vous n'êtes pas membre de ce groupe");
  }
}

function toView(s: SettlementDocument) {
  return {
    id: s._id.toString(),
    groupId: s.groupId.toString(),
    fromUserId: s.fromUserId.toString(),
    toUserId: s.toUserId.toString(),
    amount: s.amount,
    status: s.status as SettlementStatus,
    createdAt: s.createdAt,
    confirmedAt: s.confirmedAt ?? null,
  };
}

export class SettlementService {
  /** Enregistre un paiement fait hors de l'application. Statut initial : en attente. */
  async createSettlement(groupId: string, actorId: string, input: CreateSettlementInput) {
    const group = await findGroupOr404(groupId);
    assertMember(group, actorId);

    if (!mongoose.isValidObjectId(input.toUserId) || !isMember(group, input.toUserId)) {
      throw notFound('Destinataire introuvable dans ce groupe', 'MEMBER_NOT_FOUND');
    }
    if (input.toUserId === actorId) {
      throw conflict('Vous ne pouvez pas vous payer vous-même', 'SELF_SETTLEMENT');
    }

    const debt = await getPairwiseDebt(groupId, actorId, input.toUserId);
    if (input.amount > debt) {
      throw conflict(`Le montant dépasse la dette restante (${debt} XOF)`, 'AMOUNT_EXCEEDS_DEBT');
    }

    const settlement = await Settlement.create({
      groupId,
      fromUserId: actorId,
      toUserId: input.toUserId,
      amount: input.amount,
      createdBy: actorId,
    });
    return toView(settlement);
  }

  /** Liste des règlements du groupe (les plus récents d'abord), filtre optionnel par statut. */
  async listSettlements(groupId: string, actorId: string, status?: string) {
    const group = await findGroupOr404(groupId);
    assertMember(group, actorId);

    const filter: Record<string, unknown> = { groupId };
    if (status && (SETTLEMENT_STATUSES as readonly string[]).includes(status)) {
      filter.status = status;
    }

    const settlements = await Settlement.find(filter).sort({ createdAt: -1 }).limit(100);
    return settlements.map(toView);
  }

  /** Seul le destinataire peut confirmer, et une seule fois. */
  async confirmSettlement(groupId: string, settlementId: string, actorId: string) {
    const group = await findGroupOr404(groupId);
    assertMember(group, actorId);

    if (!mongoose.isValidObjectId(settlementId)) {
      throw notFound('Règlement introuvable', 'SETTLEMENT_NOT_FOUND');
    }
    const settlement = await Settlement.findOne({ _id: settlementId, groupId });
    if (!settlement) {
      throw notFound('Règlement introuvable', 'SETTLEMENT_NOT_FOUND');
    }
    if (settlement.toUserId.toString() !== actorId) {
      throw forbidden('Seul le destinataire peut confirmer ce règlement');
    }

    // Mise à jour atomique : évite une double confirmation simultanée.
    const updated = await Settlement.findOneAndUpdate(
      { _id: settlementId, groupId, status: 'en_attente' },
      { status: 'confirme', confirmedAt: new Date() },
      { new: true },
    );
    if (!updated) {
      throw conflict('Ce règlement est déjà confirmé', 'ALREADY_CONFIRMED');
    }
    return toView(updated);
  }
}
