import mongoose from 'mongoose';
import { forbidden, notFound, unprocessable } from '../../../shared/errors/app-error';
import { Group, type GroupDocument } from '../../groups/models/group.model';
import { User } from '../../users/models/user.model';
import { Expense } from '../models/expense.model';
import type { CreateExpenseInput } from '../validators/expense.validator';

interface Share {
  userId: string;
  amount: number;
}

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

function memberIdsOf(group: GroupDocument): string[] {
  return group.members.map((m) => m.userId.toString());
}

/**
 * Règle Q20 (qui peut créer une dépense) : pas encore tranchée par l'équipe.
 * Hypothèse actuelle : administrateur uniquement. Un seul endroit à modifier.
 */
function canCreateExpense(group: GroupDocument, userId: string): boolean {
  const me = group.members.find((m) => m.userId.toString() === userId);
  return me?.role === 'admin';
}

function assertAllMembers(ids: string[], memberIds: string[], code: string, message: string) {
  if (new Set(ids).size !== ids.length) {
    throw unprocessable('Participant en double', 'DUPLICATE_PARTICIPANT');
  }
  if (!ids.every((id) => memberIds.includes(id))) {
    throw unprocessable(message, code);
  }
}

/** Partage égal en entiers : le reste va aux premiers noms par ordre alphabétique. */
async function computeEqualShares(amount: number, participantIds: string[]): Promise<Share[]> {
  const users = await User.find({ _id: { $in: participantIds } })
    .select('displayName')
    .lean();
  const nameOf = new Map(users.map((u) => [u._id.toString(), u.displayName as string]));

  const sorted = [...participantIds].sort((a, b) =>
    (nameOf.get(a) ?? '').localeCompare(nameOf.get(b) ?? '', 'fr'),
  );

  const base = Math.floor(amount / sorted.length);
  const remainder = amount % sorted.length;
  return sorted.map((userId, i) => ({ userId, amount: base + (i < remainder ? 1 : 0) }));
}

function toExpense(e: InstanceType<typeof Expense>) {
  return {
    id: e._id.toString(),
    groupId: e.groupId.toString(),
    label: e.label,
    amount: e.amount,
    payerId: e.payerId.toString(),
    shares: e.shares.map((s) => ({ userId: s.userId.toString(), amount: s.amount })),
    category: e.category,
    date: e.date,
    note: e.note ?? null,
    createdBy: e.createdBy.toString(),
    createdAt: e.createdAt,
  };
}

export class ExpenseService {
  async createExpense(groupId: string, userId: string, input: CreateExpenseInput) {
    const group = await findGroupOr404(groupId);
    const memberIds = memberIdsOf(group);

    if (!memberIds.includes(userId)) {
      throw forbidden("Vous n'êtes pas membre de ce groupe");
    }
    if (!canCreateExpense(group, userId)) {
      throw forbidden("Vous n'avez pas le droit d'ajouter une dépense");
    }
    if (!memberIds.includes(input.payerId)) {
      throw unprocessable("Le payeur n'est pas membre du groupe", 'INVALID_PAYER');
    }

    let shares: Share[];
    if (input.split.type === 'equal') {
      const ids = input.split.participantIds;
      assertAllMembers(ids, memberIds, 'INVALID_PARTICIPANT', "Un participant n'est pas membre du groupe");
      shares = await computeEqualShares(input.amount, ids);
    } else {
      shares = input.split.shares;
      assertAllMembers(
        shares.map((s) => s.userId),
        memberIds,
        'INVALID_PARTICIPANT',
        "Un participant n'est pas membre du groupe",
      );
      const sum = shares.reduce((total, s) => total + s.amount, 0);
      if (sum !== input.amount) {
        throw unprocessable(
          `La somme des parts (${sum}) doit être égale au montant (${input.amount})`,
          'SHARES_MISMATCH',
        );
      }
    }

    const expense = await Expense.create({
      groupId,
      label: input.label,
      amount: input.amount,
      payerId: input.payerId,
      shares,
      category: input.category,
      date: input.date ?? new Date(),
      note: input.note,
      createdBy: userId,
    });

    return toExpense(expense);
  }
}