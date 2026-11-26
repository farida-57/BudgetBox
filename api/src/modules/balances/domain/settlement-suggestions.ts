import { compareDisplayNames } from '../../../shared/display-name-order';
import { addXof } from '../../../shared/money/xof';
import { balanceIntegrityError } from './balance-calculator';

/**
 * Suggestions de règlement (cahier des charges §4.4, réponses Q42/Q43).
 *
 * À partir des soldes nets, on propose des transferts « débiteur → créancier »
 * qui ramènent tous les soldes à zéro, en limitant leur nombre.
 * Ce sont des propositions en lecture seule : rien n'est enregistré.
 */

export interface MemberBalance {
  userId: string;
  displayName: string;
  balance: number;
}

export interface SettlementSuggestion {
  fromUserId: string;
  toUserId: string;
  amount: number;
}

interface Party {
  userId: string;
  displayName: string;
  remaining: number;
}

/**
 * Plus grand montant restant ; à égalité, premier nom alphabétique ;
 * à égalité de nom, premier dans l'ordre reçu.
 */
function pickLargest(parties: readonly Party[]): Party | undefined {
  let best: Party | undefined;
  for (const party of parties) {
    if (party.remaining === 0) {
      continue;
    }
    if (
      !best ||
      party.remaining > best.remaining ||
      (party.remaining === best.remaining && compareDisplayNames(party.displayName, best.displayName) < 0)
    ) {
      best = party;
    }
  }
  return best;
}

/**
 * Algorithme glouton :
 *   1. prendre le plus gros débiteur et le plus gros créancier ;
 *   2. proposer un transfert du plus petit des deux montants ;
 *   3. recommencer jusqu'à ce que tout le monde soit à zéro.
 * Chaque étape solde au moins une personne, donc il y a au plus
 * (nombre de personnes non soldées − 1) transferts, chacun borné par les soldes.
 */
export function suggestSettlements(balances: readonly MemberBalance[]): SettlementSuggestion[] {
  let total = 0;
  for (const entry of balances) {
    if (!Number.isSafeInteger(entry.balance)) {
      throw balanceIntegrityError('Solde non entier', [{ userId: entry.userId }]);
    }
    total = addXof(total, entry.balance);
  }
  if (total !== 0) {
    throw balanceIntegrityError('La somme des soldes du groupe n\'est pas nulle', [{ total }]);
  }

  // Copies de travail : l'entrée n'est jamais modifiée.
  const debtors: Party[] = balances
    .filter((entry) => entry.balance < 0)
    .map((entry) => ({ userId: entry.userId, displayName: entry.displayName, remaining: -entry.balance }));
  const creditors: Party[] = balances
    .filter((entry) => entry.balance > 0)
    .map((entry) => ({ userId: entry.userId, displayName: entry.displayName, remaining: entry.balance }));

  const suggestions: SettlementSuggestion[] = [];
  for (;;) {
    const debtor = pickLargest(debtors);
    const creditor = pickLargest(creditors);
    if (!debtor || !creditor) {
      break; // total nul : les deux côtés s'épuisent en même temps
    }
    const amount = Math.min(debtor.remaining, creditor.remaining);
    suggestions.push({ fromUserId: debtor.userId, toUserId: creditor.userId, amount });
    debtor.remaining -= amount;
    creditor.remaining -= amount;
  }

  return suggestions;
}
