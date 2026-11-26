/**
 * TEMPORAIRE : en attendant le module des soldes (membre 1).
 * Doit renvoyer ce que `fromUserId` doit encore à `toUserId` dans le groupe, en XOF.
 * Tant que les soldes n'existent pas, aucune limite n'est appliquée.
 * TODO : remplacer par l'appel au service de soldes du membre 1.
 */
export async function getPairwiseDebt(
  _groupId: string,
  _fromUserId: string,
  _toUserId: string,
): Promise<number> {
  return Number.MAX_SAFE_INTEGER;
}
