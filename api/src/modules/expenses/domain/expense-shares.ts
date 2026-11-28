import { unprocessable } from '../../../shared/errors/app-error';
import { compareDisplayNames } from '../../../shared/display-name-order';
import { assertXofAmount, assertXofShare, sumXof } from '../../../shared/money/xof';

/**
 * Règles de répartition d'une dépense (cahier des charges §4.3).
 *
 * Fonctions pures : aucune base de données, aucune requête HTTP.
 * Le service des dépenses (Membre 3) les appelle avant d'enregistrer une dépense ;
 * le calcul des soldes relit ensuite les parts enregistrées.
 */

/** Membre du groupe tel que renvoyé par `GroupService.listMembers`. */
export interface GroupMemberRef {
  userId: string;
  displayName: string;
}

/** Part d'un participant, stockée dans `expense.participants[]`. */
export interface ExpenseShare {
  userId: string;
  shareAmount: number;
}

export type ExpenseSplitInput =
  | { mode: 'equal'; participantIds: readonly string[] }
  | { mode: 'custom'; shares: readonly ExpenseShare[] };

export interface ComputeExpenseSharesInput {
  amount: number;
  payerId: string;
  split: ExpenseSplitInput;
  /** Membres actuels du groupe, dans l'ordre fourni par `GroupService.listMembers`. */
  members: readonly GroupMemberRef[];
}

function assertNotEmpty(items: readonly unknown[]) {
  if (items.length === 0) {
    throw unprocessable('Au moins un participant est requis', 'EMPTY_PARTICIPANTS', [
      { path: 'participants', message: 'Liste vide' },
    ]);
  }
}

function assertNoDuplicate(userIds: readonly string[]) {
  const seen = new Set<string>();
  const duplicates = new Set<string>();
  for (const userId of userIds) {
    if (seen.has(userId)) {
      duplicates.add(userId);
    }
    seen.add(userId);
  }
  if (duplicates.size > 0) {
    throw unprocessable(
      'Un participant ne peut apparaître qu\'une seule fois',
      'DUPLICATE_PARTICIPANT',
      [...duplicates].map((userId) => ({ path: 'participants', userId })),
    );
  }
}

/**
 * Partage égal en unités XOF entières.
 *
 * Exemple : 10 000 XOF entre Awa, Binta et Chérif
 *   base = 3 333, reste = 1 → Awa (1re alphabétiquement) reçoit 3 334.
 * La somme des parts est toujours exactement égale au montant.
 */
export function splitEqually(amount: number, participants: readonly GroupMemberRef[]): ExpenseShare[] {
  assertXofAmount(amount);
  assertNotEmpty(participants);
  assertNoDuplicate(participants.map((p) => p.userId));

  const count = participants.length;
  const remainder = amount % count; // entre 0 et count - 1 XOF à distribuer
  const base = (amount - remainder) / count; // division exacte : aucun arrondi

  // Tri stable : deux noms identiques gardent l'ordre reçu.
  const alphabetical = [...participants].sort((a, b) => compareDisplayNames(a.displayName, b.displayName));

  return alphabetical.map((participant, index) => ({
    userId: participant.userId,
    shareAmount: index < remainder ? base + 1 : base,
  }));
}

/**
 * Partage personnalisé : chaque part est saisie en XOF.
 * Refuse une part négative ou décimale, un participant répété
 * et toute somme différente du montant (trop basse comme trop haute).
 */
export function validateCustomShares(amount: number, shares: readonly ExpenseShare[]): ExpenseShare[] {
  assertXofAmount(amount);
  assertNotEmpty(shares);
  shares.forEach((share, index) => assertXofShare(share.shareAmount, `shares.${index}.shareAmount`));
  assertNoDuplicate(shares.map((share) => share.userId));

  const total = sumXof(shares.map((share) => share.shareAmount));
  if (total !== amount) {
    throw unprocessable('La somme des parts doit être égale au montant de la dépense', 'SHARES_SUM_MISMATCH', [
      { path: 'shares', expected: amount, actual: total },
    ]);
  }

  return shares.map((share) => ({ userId: share.userId, shareAmount: share.shareAmount }));
}

/**
 * Point d'entrée pour le service des dépenses.
 *
 * Vérifie le périmètre du groupe (payeur et participants membres), l'absence de doublon,
 * la participation du payeur (réponse Q28), puis calcule les parts.
 * Ne vérifie PAS qui a le droit de créer la dépense : cette règle (Q20) est en attente.
 */
export function computeExpenseShares(input: ComputeExpenseSharesInput): ExpenseShare[] {
  const { amount, payerId, split, members } = input;
  assertXofAmount(amount);

  const positionById = new Map(members.map((member, index) => [member.userId, index]));
  if (!positionById.has(payerId)) {
    throw unprocessable('Le payeur doit être membre du groupe', 'PAYER_NOT_MEMBER', [
      { path: 'payerId', userId: payerId },
    ]);
  }

  const participantIds = split.mode === 'equal' ? [...split.participantIds] : split.shares.map((s) => s.userId);
  assertNotEmpty(participantIds);
  assertNoDuplicate(participantIds);

  const outsiders = participantIds.filter((userId) => !positionById.has(userId));
  if (outsiders.length > 0) {
    throw unprocessable(
      'Tous les participants doivent être membres du groupe',
      'PARTICIPANT_NOT_MEMBER',
      outsiders.map((userId) => ({ path: 'participants', userId })),
    );
  }

  if (!participantIds.includes(payerId)) {
    throw unprocessable('Le payeur doit faire partie des participants', 'PAYER_NOT_PARTICIPANT', [
      { path: 'payerId', userId: payerId },
    ]);
  }

  if (split.mode === 'custom') {
    return validateCustomShares(amount, split.shares);
  }

  // Les participants sont remis dans l'ordre du groupe avant le tri alphabétique :
  // en cas d'homonymes, le résultat ne dépend pas de l'ordre envoyé par l'application.
  const participants = members.filter((member) => participantIds.includes(member.userId));
  return splitEqually(amount, participants);
}
