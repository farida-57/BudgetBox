import { AppError } from '../../../shared/errors/app-error';
import { addXof, isXofAmount, isXofShare, subtractXof, sumXof } from '../../../shared/money/xof';
import type { ExpenseShare } from '../../expenses/domain/expense-shares';

/**
 * Calcul des soldes nets d'un groupe (cahier des charges §4.4).
 *
 * Convention de signe :
 *   solde > 0 → le groupe doit cette somme à la personne ;
 *   solde < 0 → la personne doit cette somme au groupe.
 * La somme des soldes d'un groupe vaut toujours 0.
 */

/** Dépense enregistrée, telle que lue pour le calcul. */
export interface BalanceExpense {
  id: string;
  payerId: string;
  amount: number;
  participants: readonly ExpenseShare[];
}

/** Règlement enregistré : de `fromUserId` (qui paie) vers `toUserId` (qui reçoit). */
export interface BalanceSettlement {
  id: string;
  fromUserId: string;
  toUserId: string;
  amount: number;
  status: string;
}

export interface ComputeNetBalancesInput {
  /** Membres actuels : ils apparaissent même sans aucune opération (solde 0). */
  memberIds: readonly string[];
  expenses: readonly BalanceExpense[];
  settlements: readonly BalanceSettlement[];
}

/**
 * Donnée enregistrée incohérente (parts dont la somme diffère du montant, montant décimal…).
 * On préfère refuser le calcul plutôt que d'afficher des soldes faux.
 */
export function balanceIntegrityError(message: string, details: unknown[] = []) {
  return new AppError(500, 'BALANCE_INTEGRITY_ERROR', message, details);
}

function assertExpenseIntegrity(expense: BalanceExpense) {
  if (!isXofAmount(expense.amount)) {
    throw balanceIntegrityError('Montant de dépense invalide', [{ expenseId: expense.id }]);
  }
  if (expense.participants.length === 0) {
    throw balanceIntegrityError('Dépense sans participant', [{ expenseId: expense.id }]);
  }
  const seen = new Set<string>();
  let total = 0;
  for (const share of expense.participants) {
    if (!isXofShare(share.shareAmount) || seen.has(share.userId)) {
      throw balanceIntegrityError('Part de dépense invalide', [{ expenseId: expense.id, userId: share.userId }]);
    }
    seen.add(share.userId);
    total = addXof(total, share.shareAmount);
  }
  if (total !== expense.amount) {
    throw balanceIntegrityError('La somme des parts diffère du montant de la dépense', [
      { expenseId: expense.id, expected: expense.amount, actual: total },
    ]);
  }
}

function assertSettlementIntegrity(settlement: BalanceSettlement) {
  if (!isXofAmount(settlement.amount) || settlement.fromUserId === settlement.toUserId) {
    throw balanceIntegrityError('Règlement invalide', [{ settlementId: settlement.id }]);
  }
}

export function computeNetBalances(input: ComputeNetBalancesInput): Map<string, number> {
  const balances = new Map<string, number>();
  for (const memberId of input.memberIds) {
    balances.set(memberId, 0);
  }

  const credit = (userId: string, amount: number) =>
    balances.set(userId, addXof(balances.get(userId) ?? 0, amount));
  const debit = (userId: string, amount: number) =>
    balances.set(userId, subtractXof(balances.get(userId) ?? 0, amount));

  // Dépense : le payeur a avancé le total, chaque participant consomme sa part.
  for (const expense of input.expenses) {
    assertExpenseIntegrity(expense);
    credit(expense.payerId, expense.amount);
    for (const share of expense.participants) {
      debit(share.userId, share.shareAmount);
    }
  }

  // Règlement confirmé de A vers B : la dette de A et la créance de B diminuent ensemble.
  // Un règlement en attente (`pending`) ne modifie jamais les soldes.
  for (const settlement of input.settlements) {
    if (settlement.status !== 'confirmed') {
      continue;
    }
    assertSettlementIntegrity(settlement);
    credit(settlement.fromUserId, settlement.amount);
    debit(settlement.toUserId, settlement.amount);
  }

  const total = sumXof([...balances.values()]);
  if (total !== 0) {
    throw balanceIntegrityError('La somme des soldes du groupe n\'est pas nulle', [{ total }]);
  }

  return balances;
}
