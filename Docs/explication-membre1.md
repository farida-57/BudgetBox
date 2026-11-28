# Explication — Membre 1 : calculs financiers, soldes et suggestions

**Pour qui :** toute l'équipe BudgetBox, y compris les personnes qui débutent. Le but est que chacun puisse lire ce code, le modifier sans casser une règle d'argent et l'expliquer pendant la soutenance.

**Branche de travail :** `feature/balances`, créée à partir de `feature/auth-groups` (Membre 2), car les soldes ont besoin de l'authentification et des groupes. Les numéros de ligne cités ci-dessous correspondent à cette branche.

---

## 1. L'essentiel en cinq phrases

1. **Le serveur est la seule source de vérité pour l'argent.** L'application affiche les soldes ; elle ne les calcule jamais et n'en envoie jamais au serveur.
2. **Tous les montants sont des entiers XOF** : pas de centimes, pas de nombres à virgule.
3. Deux routes en **lecture seule** : `GET /api/v1/groups/:groupId/balances` et `GET /api/v1/groups/:groupId/settlement-suggestions`.
4. Les soldes sont **recalculés à chaque demande** à partir des dépenses enregistrées et des règlements **confirmés** uniquement.
5. Les règles de **répartition d'une dépense** (partage égal et personnalisé) sont prêtes dans une fonction que le service des dépenses (Membre 3) n'a qu'à appeler.

---

## 2. Carte des fichiers

### API (Node.js / TypeScript / Express 5)

| Fichier | Nouveau ? | Rôle |
|---|---|---|
| [api/src/shared/money/xof.ts](../api/src/shared/money/xof.ts) | oui | Règles des montants XOF entiers, addition contrôlée, schémas Zod réutilisables par les membres 3 et 4. |
| [api/src/shared/display-name-order.ts](../api/src/shared/display-name-order.ts) | oui | Ordre alphabétique français des noms (même règle que `GroupService.listMembers`). |
| [api/src/modules/expenses/domain/expense-shares.ts](../api/src/modules/expenses/domain/expense-shares.ts) | oui | Partage égal, partage personnalisé, contrôles payeur/participants. À appeler par le service des dépenses (Membre 3). |
| [api/src/modules/balances/domain/balance-calculator.ts](../api/src/modules/balances/domain/balance-calculator.ts) | oui | Calcul des soldes nets d'un groupe. |
| [api/src/modules/balances/domain/settlement-suggestions.ts](../api/src/modules/balances/domain/settlement-suggestions.ts) | oui | Algorithme des suggestions de règlement. |
| [api/src/modules/balances/services/balance-sources.ts](../api/src/modules/balances/services/balance-sources.ts) | oui | Lecture en base des dépenses et des règlements confirmés (contrat avec les membres 3 et 4). |
| [api/src/modules/balances/services/balance.service.ts](../api/src/modules/balances/services/balance.service.ts) | oui | Chef d'orchestre : contrôle d'accès, lecture, calcul, mise en forme de la réponse. |
| [api/src/modules/balances/controllers/balance.controller.ts](../api/src/modules/balances/controllers/balance.controller.ts) | oui | Transforme la requête HTTP en appel du service. |
| [api/src/modules/balances/routes/balance.routes.ts](../api/src/modules/balances/routes/balance.routes.ts) | oui | Déclare les deux routes GET avec `requireAuth` et la validation des paramètres. |
| [api/src/app.ts](../api/src/app.ts) | modifié | Monte les routes des soldes sous `/api/v1/groups` (lignes 6 et 32). |
| [api/requests.http](../api/requests.http) | modifié | Exemples d'appels des deux routes. |
| `api/test/expense-shares.test.ts`, `balance-calculator.test.ts`, `settlement-suggestions.test.ts`, `balances.test.ts`, `money-helpers.ts` | oui | Tests (voir section 12). |

> Pourquoi un dossier `domain/` alors que les modules du Membre 2 n'ont que `controllers/models/routes/services/validators` ? Les fonctions de `domain/` sont **pures** : pas de base de données, pas de HTTP. On les teste en quelques millisecondes, et le service des dépenses peut les réutiliser telles quelles.

### Application (Flutter / BLoC)

| Fichier | Couche | Rôle |
|---|---|---|
| `app/lib/features/balances/domain/entities/member_balance.dart` | domain | Solde d'une personne (`int balance`). |
| `app/lib/features/balances/domain/entities/group_balances.dart` | domain | Liste des soldes du groupe + `balanceOf(userId)`. |
| `app/lib/features/balances/domain/entities/settlement_suggestion.dart` | domain | Un transfert proposé. |
| `app/lib/features/balances/domain/repositories/balance_repository.dart` | domain | Contrat de lecture (aucune méthode d'écriture). |
| `app/lib/features/balances/domain/usecases/get_group_balances_usecase.dart`, `get_settlement_suggestions_usecase.dart` | domain | Cas d'usage appelés par le Cubit. |
| `app/lib/features/balances/data/models/*.dart` | data | DTO : lecture stricte du JSON (un montant doit être un entier). |
| `app/lib/features/balances/data/datasources/balance_remote_datasource.dart` | data | Appels Dio + conversion des erreurs avec le `mapDioException` central. |
| `app/lib/features/balances/data/repositories/balance_repository_impl.dart` | data | Implémentation du contrat. |
| `app/lib/features/balances/presentation/bloc/group_balances_cubit.dart`, `group_balances_state.dart` | presentation | États chargement / vide / erreur / contenu. |
| `app/lib/features/balances/presentation/widgets/group_balances_section.dart` | presentation | Section « Soldes » affichée dans le détail du groupe. |
| `app/lib/core/format/xof_format.dart` | core | Affichage français d'un entier : « 10 000 XOF ». |
| `app/lib/app/injection.dart`, `app/lib/app/app.dart` | app | Branchement des dépendances (modifiés). |
| `app/lib/features/groups/presentation/pages/group_detail_page.dart` | groups | Ajout de la section Soldes dans l'écran existant (modifié). |
| `app/test/group_balances_cubit_test.dart`, `balance_models_test.dart`, `balance_remote_datasource_test.dart`, `xof_format_test.dart` | tests | Voir section 12. |

---

## 3. Le trajet d'une requête « voir les soldes »

On suit Binta qui ouvre le groupe « Coloc » sur son téléphone.

1. **Écran** : `GroupDetailPage` crée le `GroupBalancesCubit` et appelle `load()` ([group_detail_page.dart:43-49](../app/lib/features/groups/presentation/pages/group_detail_page.dart#L43-L49)).
2. **Cubit** : `load()` émet « chargement », puis lance en parallèle les deux cas d'usage ([group_balances_cubit.dart:27-36](../app/lib/features/balances/presentation/bloc/group_balances_cubit.dart#L27-L36)).
3. **Data** : la datasource fait `GET /groups/:groupId/balances` avec Dio ([balance_remote_datasource.dart:26-37](../app/lib/features/balances/data/datasources/balance_remote_datasource.dart#L26-L37)). Le client du Membre 2 ajoute automatiquement le jeton `Authorization: Bearer …`.
4. **Routeur API** : `app.ts` monte les routes ([app.ts:32](../api/src/app.ts#L32)), puis la route passe par `requireAuth` et `validate` ([balance.routes.ts:15](../api/src/modules/balances/routes/balance.routes.ts#L15)).
5. **`requireAuth`** (Membre 2) vérifie le jeton JWT et la session, puis place l'identité dans `req.user.id`.
6. **Contrôleur** : il lit `groupId` dans l'URL et l'identité dans le jeton, **jamais dans le corps ni dans la query** ([balance.controller.ts:12-21](../api/src/modules/balances/controllers/balance.controller.ts#L12-L21)).
7. **Service** ([balance.service.ts:44-75](../api/src/modules/balances/services/balance.service.ts#L44-L75)) :
   - `groupService.getGroup()` renvoie **404** si le groupe n'existe pas et **403** si Binta n'en est pas membre (ligne 47) ;
   - `groupService.listMembers()` donne les noms, déjà triés par ordre alphabétique (ligne 48) ;
   - il lit les dépenses et les règlements confirmés (lignes 50-53) ;
   - il calcule les soldes avec `computeNetBalances` (lignes 55-59).
8. **Réponse** : du JSON. Côté app, le DTO vérifie que chaque montant est un entier, le Cubit émet « contenu » ou « vide », et le widget affiche.

---

## 4. Règle n°1 : l'argent est un entier

Fichier : [xof.ts](../api/src/shared/money/xof.ts).

- `isXofAmount` (lignes 17-19) : montant d'une dépense ou d'un règlement, **entier strictement positif**.
- `isXofShare` (lignes 22-24) : part d'un participant, **entier positif ou nul**.
- Les deux utilisent `Number.isSafeInteger`, qui refuse `NaN`, `Infinity`, `10.5`, et tout entier au-delà de 9 007 199 254 740 991. Au-delà de cette limite, JavaScript ne représente plus exactement les entiers.
- `addXof` (lignes 53-59) refuse un résultat qui sortirait de cette limite (code `AMOUNT_OUT_OF_RANGE`). Toutes les sommes du calcul passent par elle.
- `xofAmountSchema` / `xofShareSchema` (lignes 74-84) sont des schémas Zod prêts pour les validateurs des membres 3 et 4. `z.number()` refuse la chaîne `"1000"` : aucune conversion implicite.

**Pourquoi pas de virgule flottante ?** En JavaScript, `0.1 + 0.2` vaut `0.30000000000000004`. Le XOF n'a pas de centimes, donc des entiers suffisent et chaque calcul est exact.

---

## 5. Répartir une dépense

Fichier : [expense-shares.ts](../api/src/modules/expenses/domain/expense-shares.ts).

### 5.1 Partage égal — `splitEqually` (lignes 70-86)

```
reste = montant mod n                 (ligne 76)
base  = (montant − reste) / n         (ligne 77, division exacte)
les « reste » premiers noms (ordre alphabétique) reçoivent base + 1, les autres base   (lignes 80-85)
```

**Exemple du cahier** : 10 000 XOF entre Awa, Binta et Chérif.
- 10 000 mod 3 = 1 → il reste **1 XOF** à distribuer.
- base = (10 000 − 1) / 3 = **3 333**.
- Awa est première par ordre alphabétique, elle reçoit 3 334 ; Binta et Chérif reçoivent 3 333.
- Total : 3 334 + 3 333 + 3 333 = **10 000**. Rien ne se perd.

Autre exemple : 10 001 XOF à trois → reste 2 → Awa 3 334, Binta 3 334, Chérif 3 333.

**L'ordre alphabétique** utilise `Intl.Collator('fr')` ([display-name-order.ts:11-15](../api/src/shared/display-name-order.ts#L11-L15)), c'est-à-dire la même règle que `GroupService.listMembers` du Membre 2 (`localeCompare(…, 'fr')`). Ainsi « Émile » est classé avant « Eric ». Une comparaison brute des caractères l'aurait mis après « Zoé ».

**Deux personnes avec exactement le même nom** : le cahier ne dit pas qui reçoit le XOF en trop. On n'invente pas de règle : le tri est *stable* et garde l'ordre des membres du groupe ([ligne 152](../api/src/modules/expenses/domain/expense-shares.ts#L152)). Le résultat ne dépend donc pas de l'ordre envoyé par l'application. **Point à faire valider par l'équipe.**

### 5.2 Partage personnalisé — `validateCustomShares` (lignes 93-107)

Chaque part est saisie en XOF. Le serveur refuse :
- une part négative ou décimale (`INVALID_SHARE`, ligne 96) ;
- un participant répété (`DUPLICATE_PARTICIPANT`, ligne 97) ;
- une somme différente du total, trop basse **ou** trop haute (`SHARES_SUM_MISMATCH`, lignes 99-104). L'erreur indique la somme attendue et la somme reçue, ce qui permet au formulaire d'afficher « 8 000 saisis sur 9 000 ».

### 5.3 Point d'entrée pour le Membre 3 — `computeExpenseShares` (lignes 116-154)

Les contrôles se font dans cet ordre :

| Ligne | Contrôle | Code d'erreur (HTTP 422) |
|---|---|---|
| 118 | montant entier > 0 | `INVALID_AMOUNT` |
| 121-125 | le payeur est membre du groupe | `PAYER_NOT_MEMBER` |
| 128-129 | au moins un participant, pas de doublon | `EMPTY_PARTICIPANTS`, `DUPLICATE_PARTICIPANT` |
| 131-138 | tous les participants sont membres | `PARTICIPANT_NOT_MEMBER` |
| 140-144 | le payeur fait partie des participants (réponse Q28) | `PAYER_NOT_PARTICIPANT` |
| 146-153 | calcul des parts (personnalisé ou égal) | `SHARES_SUM_MISMATCH`, `INVALID_SHARE` |

Ce que la fonction **ne fait pas** : décider *qui a le droit* de créer une dépense. Cette règle (Q20) n'est pas encore tranchée.

Exemple d'appel dans le futur service des dépenses :

```ts
const members = await groupService.listMembers(groupId, req.user!.id); // 403/404 si besoin
const participants = computeExpenseShares({
  amount: body.amount,
  payerId: body.payerId,
  split: body.split, // { mode: 'equal', participantIds } ou { mode: 'custom', shares }
  members,
});
await Expense.create({ groupId, payerId: body.payerId, amount: body.amount, participants /* , … */ });
```

---

## 6. Calculer les soldes

Fichier : [balance-calculator.ts](../api/src/modules/balances/domain/balance-calculator.ts), fonction `computeNetBalances` (lignes 75-112).

### 6.1 La formule

> **solde(personne)** = ce qu'elle a avancé − ce qu'elle a consommé + règlements confirmés qu'elle a payés − règlements confirmés qu'elle a reçus

- **solde > 0** : le groupe lui doit cette somme.
- **solde < 0** : elle doit cette somme au groupe.

### 6.2 Le code, bloc par bloc

1. **Lignes 76-79** : chaque membre actuel commence à 0. Ainsi un membre sans dépense apparaît quand même, avec 0.
2. **Lignes 81-84** : `credit` ajoute et `debit` retire, toujours avec l'addition contrôlée `addXof`.
3. **Lignes 87-93 (dépenses)** : le payeur est crédité du **total** (ligne 89), puis chaque participant est débité de **sa part** (lignes 90-92).
4. **Lignes 97-104 (règlements)** : un règlement qui n'est pas `confirmed` est **ignoré** (lignes 98-100). Pour un règlement confirmé de A vers B, A est crédité (sa dette baisse, ligne 102) et B est débité (sa créance baisse, ligne 103).
5. **Lignes 106-109** : vérification finale, la somme des soldes doit valoir **0**.

**Pourquoi la somme vaut toujours 0 ?** Une dépense ajoute `+montant` au payeur et retire la somme des parts, qui vaut exactement `montant`. Un règlement ajoute `+x` à l'un et retire `x` à l'autre. Chaque opération est donc neutre pour le groupe.

**Si la base contient une donnée fausse** (parts dont la somme diffère du montant, montant décimal…), `assertExpenseIntegrity` (lignes 46-67) l'arrête : l'API répond `500 BALANCE_INTEGRITY_ERROR` au lieu d'afficher des soldes faux. Cela ne doit jamais arriver si le service des dépenses utilise `computeExpenseShares`.

### 6.3 Exemple complet (cahier §4.7)

| Étape | Awa | Binta | Chérif | Somme |
|---|---:|---:|---:|---:|
| Awa paie 10 000, partage égal | +10 000 − 3 334 = **+6 666** | **−3 333** | **−3 333** | 0 |
| Binta enregistre un règlement de 2 000 vers Awa, **en attente** | +6 666 | −3 333 | −3 333 | 0 (rien ne change) |
| Awa **confirme** le règlement | 6 666 − 2 000 = **+4 666** | −3 333 + 2 000 = **−1 333** | −3 333 | 0 |

Binta doit encore 1 333 XOF. BudgetBox n'a déplacé aucun argent : il enregistre seulement un paiement fait en dehors de l'application.

### 6.4 Une personne retirée du groupe

Si Diane a des dettes puis est retirée du groupe, l'ignorer casserait la somme nulle. Le service l'affiche donc avec `isMember: false` ([balance.service.ts:96-120](../api/src/modules/balances/services/balance.service.ts#L96-L120)). Elle n'a plus accès au groupe (403), mais son solde reste visible pour les autres. **La politique de départ d'un membre reste à valider** (cahier §12, point 5).

---

## 7. Les suggestions de règlement

Fichier : [settlement-suggestions.ts](../api/src/modules/balances/domain/settlement-suggestions.ts), fonction `suggestSettlements` (lignes 60-94).

### 7.1 L'algorithme (glouton)

1. **Lignes 61-70** : vérifier que chaque solde est entier et que leur somme vaut 0.
2. **Lignes 73-78** : séparer les **débiteurs** (solde < 0) et les **créanciers** (solde > 0), dans des copies. Les données reçues ne sont jamais modifiées.
3. **Lignes 81-91**, en boucle :
   - prendre le plus gros débiteur et le plus gros créancier (`pickLargest`, lignes 35-50 ; à égalité, le premier par ordre alphabétique) ;
   - proposer un transfert du **plus petit** des deux montants (ligne 87) ;
   - retirer ce montant des deux côtés (lignes 89-90). Au moins une des deux personnes arrive à 0 ;
   - recommencer tant qu'il reste quelqu'un à solder.

**Garanties** (vérifiées par les tests) :
- après les transferts proposés, **tous les soldes valent 0** ;
- chaque montant est un entier > 0, **borné** par la dette du payeur et par la créance du receveur (réponse Q43) ;
- chaque étape solde au moins une personne, donc il y a **au plus (n − 1) transferts** pour n personnes non soldées ;
- **lecture seule** : rien n'est écrit en base. Le test d'intégration compte les règlements avant et après : 0 dans les deux cas.

> Honnêteté technique : la méthode gloutonne **réduit** le nombre de transferts (réponse Q42), mais elle ne garantit pas le minimum absolu dans tous les cas. Trouver le vrai minimum est un problème combinatoire difficile, disproportionné pour des groupes de 3 à 10 personnes. Le plan d'équipe ne fixe pas d'algorithme précis : ce choix doit être **validé par l'équipe**.

### 7.2 Exemples

- Soldes `Awa +6 666, Binta −3 333, Chérif −3 333` → **Binta → Awa 3 333** et **Chérif → Awa 3 333**.
- Après le règlement confirmé de 2 000 : `Awa +4 666, Binta −1 333, Chérif −3 333` → **Chérif → Awa 3 333** (le plus gros débiteur d'abord), puis **Binta → Awa 1 333**.
- Soldes `Diane +2 500, Ebou −2 500, Awa +100, Binta −100` → **Ebou → Diane 2 500**, **Binta → Awa 100**. Les montants égaux sont associés directement.

---

## 8. Sécurité et droits d'accès

- **Identité** : uniquement celle du jeton vérifié par `requireAuth`. Un `?userId=` ajouté par un client est ignoré : un intrus qui envoie l'identifiant d'Awa reçoit quand même 403 ([balances.test.ts:233](../api/test/balances.test.ts#L233)).
- **Appartenance** : on réutilise `GroupService.getGroup` et `listMembers` du Membre 2 au lieu de dupliquer la règle. Groupe absent ou identifiant invalide → **404** ; non-membre → **403** ; sans jeton → **401**.
- **Aucune route d'écriture des soldes** : `POST /groups/:id/balances` renvoie 404 ([balances.test.ts:256](../api/test/balances.test.ts#L256)). Un solde envoyé par l'application ne peut donc jamais devenir une vérité.

---

## 9. Contrat REST

`GET /api/v1/groups/:groupId/balances` → **200**

```json
{
  "groupId": "665f…",
  "currency": "XOF",
  "balances": [
    { "userId": "…", "displayName": "Awa",    "balance": 6666,  "isMember": true },
    { "userId": "…", "displayName": "Binta",  "balance": -3333, "isMember": true },
    { "userId": "…", "displayName": "Chérif", "balance": -3333, "isMember": true }
  ]
}
```

`GET /api/v1/groups/:groupId/settlement-suggestions` → **200**

```json
{
  "groupId": "665f…",
  "currency": "XOF",
  "suggestions": [
    { "fromUserId": "…", "fromDisplayName": "Binta",  "toUserId": "…", "toDisplayName": "Awa", "amount": 3333 },
    { "fromUserId": "…", "fromDisplayName": "Chérif", "toUserId": "…", "toDisplayName": "Awa", "amount": 3333 }
  ]
}
```

Erreurs : format commun `{ "error": { "code", "message", "details" } }` (401, 403 `FORBIDDEN`, 404 `GROUP_NOT_FOUND`, 500 `BALANCE_INTEGRITY_ERROR`).

Les réponses suivent la convention du Membre 2 : objet JSON direct, sans enveloppe `{ data: … }`. Les noms `fromUserId` / `toUserId` / `amount` sont les mêmes que dans le corps de `POST /settlements` du Membre 4 : une suggestion pourra préremplir son formulaire.

---

## 10. Contrat de stockage avec les membres 3 et 4

Le calcul lit directement deux collections MongoDB ([balance-sources.ts:11-26](../api/src/modules/balances/services/balance-sources.ts#L11-L26)) :

| Collection | Champs lus | Propriétaire |
|---|---|---|
| `expenses` | `groupId` (ObjectId), `payerId` (ObjectId), `amount` (entier), `participants: [{ userId, shareAmount }]` | Membre 3 |
| `settlements` | `groupId`, `fromUserId`, `toUserId`, `amount` (entier), `status: 'pending' \| 'confirmed'` | Membre 4 |

Ces noms reprennent le « contrat provisoire » documenté par le Membre 4 dans sa branche. Les règlements sont filtrés sur `status: 'confirmed'` **dans la requête** (ligne 77), et le calculateur ignore encore une fois les autres statuts, par sécurité.

**Si un membre change un nom de champ**, une seule classe est à adapter : `MongoBalanceSources` ([balance-sources.ts:51-89](../api/src/modules/balances/services/balance-sources.ts#L51-L89)). Les tests d'intégration le signaleront immédiatement.

---

## 11. Côté Flutter

### 11.1 Les couches

- **domain** : entités et contrats, en Dart pur. Aucune importation de Flutter ni de Dio, seulement `equatable`, comme dans le domaine du Membre 2.
- **data** : DTO, datasource et repository.
- **presentation** : Cubit, états et widget.

### 11.2 Lecture stricte du JSON

`readInt` ([json_readers.dart:15-21](../app/lib/features/balances/data/models/json_readers.dart#L15-L21)) accepte **uniquement un entier**. `3333.5`, `3333.0` ou `"3333"` provoquent une `FormatException`. La datasource la transforme en `UnknownFailure` (« Réponse inattendue du serveur ») ([balance_remote_datasource.dart:34-35](../app/lib/features/balances/data/datasources/balance_remote_datasource.dart#L34-L35)). Les erreurs HTTP passent par le **`mapDioException` central** (ligne 33) : un 403 devient `ServerFailure(statusCode: 403, code: 'FORBIDDEN')`.

### 11.3 Le Cubit

[group_balances_cubit.dart:27-52](../app/lib/features/balances/presentation/bloc/group_balances_cubit.dart#L27-L52)

- Ligne 28 : état **chargement**.
- Lignes 32-36 : les deux requêtes partent en parallèle. `Future.wait` attend les deux et, si l'une échoue, relance l'erreur d'origine (une `Failure`).
- Lignes 38-44 : si tous les soldes valent 0 → état **vide** (« Tous les comptes sont équilibrés ») ; sinon → état **contenu**, avec les données **telles que reçues**.
- Lignes 45-51 : `Failure` → état **erreur** avec le message du serveur ; toute autre erreur → message générique.
- Lignes 55-59 : on n'émet plus rien si la page a été fermée pendant le chargement.

Le Cubit ne fait **aucune addition** : il choisit seulement l'état à afficher.

### 11.4 L'affichage

- La section utilise un `switch` sur les quatre états ([group_balances_section.dart:43-58](../app/lib/features/balances/presentation/widgets/group_balances_section.dart#L43-L58)). En cas d'erreur, un bouton **Réessayer** rappelle `load()` (lignes 93-96).
- « Votre solde » traduit le signe en phrase ([lignes 168-177](../app/lib/features/balances/presentation/widgets/group_balances_section.dart#L168-L177)) : « Le groupe vous doit 6 666 XOF », « Vous devez 3 333 XOF au groupe » ou « Vous êtes à jour ».
- Les suggestions rappellent qu'il s'agit de **propositions** : le paiement se fait hors de BudgetBox.
- `formatXof` ([xof_format.dart:12-29](../app/lib/core/format/xof_format.dart#L12-L29)) insère une espace fine insécable (U+202F) tous les trois chiffres, **en travaillant sur les chiffres de l'entier**, sans jamais passer par un `double`. Exemple : `10000` → « 10 000 XOF ».

### 11.5 Branchement

- [injection.dart:84-85](../app/lib/app/injection.dart#L84-L85) : création de la datasource et du repository ; lignes 101-102 : création des cas d'usage.
- [app.dart:45-48](../app/lib/app/app.dart#L45-L48) : exposition des cas d'usage par `RepositoryProvider`.
- [group_detail_page.dart:31-52](../app/lib/features/groups/presentation/pages/group_detail_page.dart#L31-L52) : `MultiBlocProvider` avec le Cubit du détail (Membre 2) et le Cubit des soldes ; ligne 177 : insertion de la section ; ligne 124 : rechargement des soldes après le retrait d'un membre.

---

## 12. Les tests et ce qu'ils prouvent

| Règle | Test |
|---|---|
| Montant décimal, négatif, NaN, infini, trop grand ou texte → refusé | [expense-shares.test.ts:17](../api/test/expense-shares.test.ts#L17) |
| Partage égal exact | [expense-shares.test.ts:41](../api/test/expense-shares.test.ts#L41) |
| Reste attribué par ordre alphabétique (exemple du cahier) | [expense-shares.test.ts:46](../api/test/expense-shares.test.ts#L46), [:57](../api/test/expense-shares.test.ts#L57) |
| Ordre français (accents) | [expense-shares.test.ts:62](../api/test/expense-shares.test.ts#L62) |
| Somme des parts toujours exacte (49 cas) | [expense-shares.test.ts:82](../api/test/expense-shares.test.ts#L82) |
| Liste vide, montant invalide, doublon | [expense-shares.test.ts:95-108](../api/test/expense-shares.test.ts#L95-L108) |
| Partage personnalisé : juste, trop bas, trop haut, part invalide | [expense-shares.test.ts:111-160](../api/test/expense-shares.test.ts#L111-L160) |
| Payeur participant accepté ; payeur ou participant hors groupe refusé ; payeur non participant refusé | [expense-shares.test.ts:163-258](../api/test/expense-shares.test.ts#L163-L258) |
| Soldes après une ou plusieurs dépenses, somme nulle | [balance-calculator.test.ts:37-61](../api/test/balance-calculator.test.ts#L37-L61) |
| Règlement confirmé appliqué / en attente ignoré | [balance-calculator.test.ts:63-75](../api/test/balance-calculator.test.ts#L63-L75) |
| Données corrompues refusées | [balance-calculator.test.ts:83-110](../api/test/balance-calculator.test.ts#L83-L110) |
| Suggestions qui soldent le groupe, ≤ n − 1, bornées (200 cas générés) | [settlement-suggestions.test.ts:38-86](../api/test/settlement-suggestions.test.ts#L38-L86) |
| Suggestions en lecture seule | [settlement-suggestions.test.ts:88](../api/test/settlement-suggestions.test.ts#L88), [balances.test.ts:186](../api/test/balances.test.ts#L186) |
| Endpoints de bout en bout (vrai JWT, vrais groupes, base en mémoire) | [balances.test.ts:98-230](../api/test/balances.test.ts#L98-L230) |
| Non-membre 403, sans jeton 401, groupe absent 404, aucune écriture possible | [balances.test.ts:232-263](../api/test/balances.test.ts#L232-L263) |
| Membre retiré : solde conservé, accès perdu | [balances.test.ts:265](../api/test/balances.test.ts#L265) |
| Cubit : contenu, vide, erreur API 403, erreur réseau, erreur inattendue, réessai | [group_balances_cubit_test.dart:76-178](../app/test/group_balances_cubit_test.dart#L76-L178) |
| JSON : un montant non entier est refusé | `app/test/balance_models_test.dart` |
| Datasource : bonne URL, 403 → `ServerFailure` via le mapping central | `app/test/balance_remote_datasource_test.dart` |
| Formatage « 10 000 XOF » sans arrondi | `app/test/xof_format_test.dart` |
| Widget : contenu (« Vous devez 3 333 XOF au groupe »), vide, erreur + Réessayer, chargement | `app/test/group_balances_section_test.dart` |

Aucun test ne fixe la règle Q20 (qui peut créer une dépense), puisqu'elle n'est pas décidée.

---

## 13. Commandes de vérification

```bash
# API
cd api
npm run typecheck     # vérification TypeScript
npm test              # 93 tests (dont 69 pour cette partie), MongoDB en mémoire

# Application (SDK Flutter requis)
cd app
flutter pub get
flutter analyze       # aucune erreur ; voir les remarques ci-dessous
flutter test          # 41 tests (dont 26 pour cette partie)
```

Avec Flutter 3.50, `flutter analyze` signale seulement :
- des « info » `deprecated_member_use` sur `package:flutter/material.dart` dans tous les écrans du projet (Flutter 3.47+ conseille le paquet `material_ui`) : à migrer ensemble, pour tout le projet ;
- un « warning » `unawaited_return_in_try_block` dans `auth_repository_impl.dart:49` (code du Membre 2) : il faut écrire `return await _persistAndReturn(payload);` pour que le `try` attrape aussi ses erreurs.

`app/pubspec.yaml` déclare `intl: any` au lieu de `intl: 0.20.2` : c'est `flutter_localizations` qui impose la version d'`intl` selon le SDK installé (0.20.2 avec Flutter 3.38, 0.20.3 avec Flutter 3.50). Sans ce changement, `flutter pub get` échoue avec Flutter 3.50.

---

## 14. Décisions en attente et points d'attention

1. **Q20 — qui peut créer une dépense ?** Non tranché ; non codé ici.
2. **Algorithme des suggestions** : méthode gloutonne proposée (section 7). À valider par l'équipe.
3. **Homonymes dans le partage égal** : ordre du groupe conservé (section 5.1). À valider.
4. **Part personnalisée nulle du payeur** : acceptée (« part non négative »). Si l'équipe veut que le payeur participe avec une part strictement positive, c'est une ligne à ajouter dans `computeExpenseShares`.
5. **Membre retiré avec un solde** : affiché `isMember: false` ; politique de départ à valider (cahier §12, point 5).
6. **Intégration avec la branche du Membre 4** (`feature/settlement-api`), qui a été écrite sur un squelette séparé :
   - réponses enveloppées dans `{ data: … }` alors que le reste de l'API renvoie l'objet directement ;
   - champ `currencyCode` côté règlement, `currency` côté groupe ;
   - authentification temporaire par en-tête `X-User-Id`, à remplacer par `requireAuth` ;
   - son `settlement.context.ts` réenregistre un modèle Mongoose `Group` : si son fichier est chargé avant celui du Membre 2, `model('Group')` du Membre 2 lèvera `OverwriteModelError` ;
   - son plafond de dette (`getAllowedDebt`) compte les règlements **en attente** comme réservés. C'est cohérent avec nos soldes (qui ne les comptent pas) : cela empêche d'enregistrer deux fois la même dette. Cette convention doit cependant être confirmée ensemble. La convention de signe (A paie B → solde de A +x, de B −x) est identique.
7. **Remarque sur le code du Membre 2** : `GroupDetailCubit.load()` utilise `(a, b).wait`. En cas d'échec, l'erreur est un `ParallelWaitError` et `e.toString()` affiche « ParallelWaitError: … » à l'écran. Le Cubit des soldes évite ce cas avec `Future.wait`.

---

## 15. Questions probables en soutenance

- **Pourquoi des entiers et pas des `double` ?** Le XOF n'a pas de centimes, et les `double` créent des erreurs d'arrondi (`0.1 + 0.2 ≠ 0.3`). Avec des entiers, chaque calcul est exact.
- **Qui reçoit le XOF en trop dans un partage égal ?** Les premiers noms par ordre alphabétique français, un XOF chacun (réponse Q30).
- **Pourquoi la somme des soldes vaut-elle 0 ?** Chaque dépense et chaque règlement ajoute à quelqu'un exactement ce qu'il retire à d'autres. Le code le vérifie à chaque calcul.
- **Pourquoi un règlement en attente ne change-t-il rien ?** Tant que le destinataire n'a pas confirmé avoir reçu l'argent, rien ne prouve que le paiement a eu lieu (réponse Q44).
- **Les suggestions peuvent-elles créer un règlement ?** Non. Ce sont des calculs en lecture seule ; un test vérifie que la collection des règlements reste vide.
- **Pourquoi l'application ne calcule-t-elle pas elle-même les soldes ?** Une application peut être modifiée par un utilisateur ; le serveur, non. Les règles d'argent et de droits s'exécutent donc sur l'API.
- **Que se passe-t-il si quelqu'un modifie la base à la main ?** Le calcul vérifie l'intégrité de chaque dépense et refuse (erreur 500 explicite) plutôt que d'afficher des soldes faux.
