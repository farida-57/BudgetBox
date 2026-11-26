/**
 * Ordre alphabétique des noms d'affichage, selon les règles du français.
 *
 * C'est la même comparaison que `localeCompare(b, 'fr')`, utilisée par
 * `GroupService.listMembers` : « Émile » est classé avant « Eric », alors qu'une
 * comparaison brute des codes Unicode le placerait après « Zoé ».
 *
 * Les tris JavaScript sont stables : deux noms identiques gardent l'ordre
 * dans lequel ils ont été fournis (aucune règle de départage n'est inventée).
 */
const frenchCollator = new Intl.Collator('fr');

export function compareDisplayNames(a: string, b: string): number {
  return frenchCollator.compare(a, b);
}
