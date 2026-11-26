# Cahier des charges BudgetBox

**Version 1.0 — périmètre de départ**  
**Sujet :** T13 — BudgetBox, dépenses partagées  
**Équipe :** 5 membres — thème déclaré réservé selon la réponse au questionnaire  
**Public prioritaire :** colocataires; groupes de voyage également visés  
**Plateforme de départ :** Android  
**Devise choisie :** XOF  
**Langue de départ :** français

## 1. Objet du document

Ce cahier des charges décrit le comportement attendu de la première version de BudgetBox, ses règles métier, ses limites et ses critères de validation. Il s’appuie sur les réponses fournies dans `Reponses_questionnaire.docx` et sur les consignes du Project Book pour le thème T13. Les réponses de l’équipe sont distinguées des hypothèses retenues pour combler les cases vides.

Le périmètre principal reste celui du sujet T13 : groupes, dépenses, répartitions, soldes, suggestions de règlement, règlements et historique. Les demandes supplémentaires qui figuraient dans le questionnaire sont conservées dans le registre des décisions, mais ne sont pas automatiquement ajoutées à la V1. Le Project Book impose par ailleurs au moins une fonctionnalité avancée : un choix doit donc être confirmé avant de figer M1.

## 2. Résumé du produit

BudgetBox permet à des colocataires ou à un groupe de voyageurs de garder une trace commune des dépenses. Un membre enregistre ce qu’il a payé et indique les participants. Le serveur vérifie les règles, calcule la part de chacun et met à jour les soldes. L’application propose ensuite des transferts pour équilibrer les comptes. Elle n’envoie pas d’argent : un règlement est enregistré après un paiement fait en dehors de BudgetBox.

Le problème prioritaire est l’oubli des dépenses et le manque de transparence. L’application doit être rapide à utiliser au moment de payer et compréhensible par les autres membres du groupe.

## 3. Utilisateurs et droits

### Rôles proposés

- **Administrateur du groupe** : personne qui crée le groupe. Gère ses paramètres, les invitations et les membres. Consulte les dépenses. La réponse « Administrateur » est interprétée comme un rôle propre au groupe, pas comme un administrateur global de toute l’application.
- **Membre** : rejoint un groupe par invitation et consulte les données du groupe dont il est membre.
- **Payeur d’une dépense** : membre désigné comme ayant avancé le montant. Selon la réponse au questionnaire, le payeur et l’administrateur peuvent modifier ou supprimer cette dépense.

### Matrice d’accès initiale

| Action | Administrateur du groupe | Membre ordinaire | Payeur de la dépense |
|---|---:|---:|---:|
| Lire les dépenses du groupe | Oui | Oui | Oui |
| Créer un groupe | Oui, en devenant son administrateur | Oui, pour son propre groupe | Oui |
| Inviter ou retirer un membre | Oui | Non | Non |
| Ajouter une dépense | **À confirmer** : la réponse Q20 dit que tous les membres ne le peuvent pas; hypothèse minimale : administrateur uniquement en V1 | À confirmer | À confirmer |
| Modifier / supprimer une dépense | Oui | Non | Oui, pour sa dépense |
| Lire soldes et historique | Oui | Oui | Oui |
| Enregistrer un règlement | Oui | Oui, si les deux personnes sont membres | Oui |

Les endpoints contrôlent l’appartenance au groupe côté serveur à chaque requête. L’identifiant du groupe ou du membre transmis par l’application ne suffit jamais à autoriser une opération.

## 4. Fonctionnement complet de la V1

### 4.1 Création du compte et connexion

1. La personne crée un compte avec son nom d’affichage, son courriel et un mot de passe.
2. Le serveur vérifie les champs et conserve uniquement un hachage sécurisé du mot de passe.
3. La connexion renvoie un jeton d’accès de courte durée et un jeton de renouvellement rotatif. L’application conserve les jetons dans un stockage sécurisé Android.
4. La déconnexion révoque la session de cet appareil, conformément à la réponse Q59.

La réponse Q17 demande une vérification de courriel. Elle est enregistrée comme demande explicite mais classée hors socle tant qu’on cherche une V1 sans extras. Si l’équipe la maintient, il faudra un service d’envoi de courriel et des accès SMTP/API.

### 4.2 Création et adhésion à un groupe

1. L’administrateur crée un groupe, choisit son nom et sa devise XOF.
2. Le serveur ajoute le créateur comme administrateur et membre.
3. L’administrateur génère un lien d’invitation à usage unique.
4. Une personne connectée ouvre le lien, confirme son adhésion et devient membre.
5. L’API refuse tout accès aux dépenses, soldes ou membres par une personne qui n’appartient pas à ce groupe.
6. Un membre peut appartenir à plusieurs groupes. Le propriétaire peut retirer un membre. Un groupe fermé reste consultable en lecture seule par les anciens membres si l’administrateur le choisit; la suppression complète doit suivre la politique de conservation à confirmer.

Les liens d’invitation sont à usage unique, à valeur non devinable et stockés sous forme hachée. La réponse Q58 « ne pas limiter » ne s’applique pas aux tentatives techniques : une protection contre les essais répétés sera ajoutée pour éviter la devinette des liens. Elle ne limite pas le nombre normal de membres ou d’invitations.

### 4.3 Création et partage d’une dépense

La fiche contient : libellé, montant entier, devise du groupe, payeur, participants, catégorie, date, note éventuelle et auteur de la saisie. Le montant est positif. Les participants appartiennent tous au groupe. Selon la réponse Q28, le payeur participe à la dépense dans la V1; le partage peut porter sur un sous-groupe de membres.

- **Partage égal :** le serveur divise le total en unités entières. Le reste est distribué selon l’ordre alphabétique des noms d’affichage, comme demandé en Q30. La somme des parts reste strictement égale au montant.
- **Partage personnalisé :** la personne saisit un montant entier pour chaque participant. Le serveur refuse toute somme différente du total, toute part négative, les participants répétés et les non-membres.
- **Catégories :** liste initiale proposée : alimentation, logement, transport, activités, factures et autre. La réponse Q34 autorise les catégories personnalisées; elles pourront être créées par l’administrateur, avec un libellé obligatoire et un plafond raisonnable.
- **Date :** date du jour par défaut, affichée en français au format jour/mois/année. Une date passée est permise pour saisir une dépense oubliée; une date future est refusée.

Les reçus photo demandés en Q36 sont classés comme extension, car ils ajoutent stockage et téléversement de fichiers. Le socle V1 conserve le champ note et n’exige pas de photo.

### 4.4 Soldes et suggestions

Les soldes sont calculés uniquement par l’API à partir des dépenses et règlements enregistrés. Un solde positif signifie que le groupe doit cette somme à la personne; un solde négatif signifie que cette personne doit au groupe. La somme des soldes d’un groupe doit toujours être zéro.

Pour chaque dépense, le serveur crédite le payeur du total, puis débite chaque participant de sa part. Pour un règlement confirmé de A (payeur du règlement) vers B (destinataire), il augmente le solde net de A du montant réglé et diminue celui de B du même montant. Ainsi, la dette de A et le crédit de B se réduisent ensemble. Les calculs utilisent des entiers; aucune virgule flottante n’est utilisée pour l’argent.

Les suggestions rapprochent les soldes créditeurs et débiteurs et proposent un nombre réduit de transferts. Elles ne sont pas des paiements. Le membre réalise le transfert hors application, puis l’enregistre. L’algorithme et les cas de test sont définis dans le plan d’équipe.

### 4.5 Règlements

Un membre enregistre un règlement entre deux membres du même groupe. Le montant doit être un entier positif; un règlement partiel est autorisé si le total ne dépasse pas la dette nette restante. Selon Q44, le destinataire confirme le règlement. Avant confirmation, le règlement est en attente et ne modifie pas les soldes; après confirmation, l’API le prend en compte. Un membre ne peut pas confirmer son propre règlement.

Le règlement représente une opération faite hors de l’application. Aucun portefeuille, carte bancaire ou transfert réel n’est intégré en V1. Toute modification ou annulation après confirmation est bloquée; il faudra demander à l’administrateur de corriger par une dépense/règlement explicite, décision à confirmer.

### 4.6 Historique

L’historique contient les dépenses et règlements du groupe. Les filtres demandés sont : membre, catégorie, période, payeur et type d’opération. Le tri par défaut est du plus récent au plus ancien; les pages contiennent 20 éléments, avec un maximum API de 50. La recherche textuelle est reportée pour rester dans le périmètre initial.

En cas de réseau indisponible, l’application affiche le dernier historique mis en cache. Les modifications hors ligne ne sont pas autorisées dans la V1.

### 4.7 Exemple concret de calcul

Un groupe de trois membres enregistre une dépense de **10 000 XOF** payée par Awa et partagée également entre Awa, Binta et Chérif. Les noms définissent l’ordre alphabétique : Awa reçoit une part de 3 334 XOF; Binta et Chérif reçoivent chacun 3 333 XOF. Les parts totalisent 10 000 XOF. Awa a avancé 10 000 XOF mais supporte 3 334 XOF de sa propre part : son crédit net est 6 666 XOF. Binta et Chérif doivent chacun 3 333 XOF. La somme des soldes vaut zéro.

Si Binta règle 2 000 XOF à Awa et que celle-ci confirme le règlement, le serveur augmente le solde de Binta de 2 000 (il devient moins négatif) et diminue celui d’Awa de 2 000. Binta doit encore 1 333 XOF; aucun transfert bancaire n’est déclenché par l’application.

## 5. Contrat REST de départ

Préfixe `/api/v1`. Tous les endpoints de groupe requièrent un jeton valide et vérifient l’appartenance/les rôles sur l’API. Les listes acceptent `page` et `limit` plafonné à 50. Erreur commune : `{ "error": { "code": "...", "message": "...", "details": [] } }`.

| Méthode et chemin | Rôle | Succès | Refus principaux |
|---|---|---:|---|
| `POST /auth/register` | Public | 201 | 422 champs invalides; 409 courriel pris; 429 essais trop fréquents |
| `POST /auth/login` | Public | 200 | 401 identifiants invalides; 429 limitation |
| `POST /auth/refresh` | Session valide | 200 | 401 jeton expiré/réutilisé |
| `POST /auth/logout` | Connecté | 204 | 401 sans session valide |
| `GET /groups` | Connecté | 200 | 422 filtre invalide |
| `POST /groups` | Connecté | 201 | 422 nom/devise invalide |
| `GET /groups/:groupId` | Membre | 200 | 403/404 non-membre ou groupe absent |
| `PATCH /groups/:groupId` | Administrateur du groupe | 200 | 403, 404 ou 422 |
| `GET /groups/:groupId/members` | Membre | 200 | 403/404 |
| `POST /groups/:groupId/invitations` | Administrateur du groupe | 201 | 403/404, 429 |
| `POST /invitations/:token/accept` | Connecté, lien encore valide | 200 | 404 lien faux/expiré/déjà utilisé; 409 déjà membre |
| `DELETE /groups/:groupId/members/:userId` | Administrateur du groupe | 204 | 403/404; refus si dernier administrateur |
| `GET /groups/:groupId/expenses` | Membre | 200 | 403/404; 422 filtre/pagination invalide |
| `POST /groups/:groupId/expenses` | En attente de la décision Q20 | 201 | 403 droit insuffisant; 422 montant/parts/membres invalides |
| `PATCH /groups/:groupId/expenses/:expenseId` | Administrateur ou payeur | 200 | 403/404; 409 dépense déjà réglée; 422 champs invalides |
| `DELETE /groups/:groupId/expenses/:expenseId` | Administrateur ou payeur | 204 | 403/404; 409 dépense déjà réglée |
| `GET /groups/:groupId/balances` | Membre | 200 | 403/404; soldes calculés à la demande par l’API |
| `GET /groups/:groupId/settlement-suggestions` | Membre | 200 | 403/404; lecture seule |
| `GET /groups/:groupId/settlements` | Membre | 200 | 403/404; liste paginée |
| `POST /groups/:groupId/settlements` | Membre | 201 (pending) | 403/404; 422 montant, solde ou membres invalides |
| `POST /groups/:groupId/settlements/:id/confirm` | Destinataire | 200 (confirmed) | 403 si autre utilisateur; 404; 409 déjà confirmé |

Les endpoints de correction peuvent être retirés du périmètre si l’enseignant recommande un journal immuable. La règle minimale reste : ne jamais modifier une dépense après confirmation d’un règlement qui dépend d’elle.

## 6. Écrans de l’application

1. **Connexion / inscription** : courriel et mot de passe, validation, messages d’erreur explicites.
2. **Accueil** : groupes de la personne et accès à ses dépenses. État vide avec invitation à créer ou rejoindre un groupe.
3. **Détail d’un groupe** : devise, membres, solde de l’utilisateur, propositions de règlement, historique et filtres.
4. **Nouvelle dépense** : formulaire avec sélection payeur/participants, partage égal ou personnalisé, catégorie, date et note.
5. **Nouveau règlement** : membre destinataire, montant et confirmation par la personne concernée.
6. **Invitations et membres** : administrateur crée/renouvelle un lien à usage unique et gère les membres.
7. **Profil** : nom d’affichage et déconnexion. La photo de profil demandée en Q54 est différée avec le téléversement de fichiers.

Chaque écran chargé depuis l’API possède les états chargement, vide, erreur avec réessai et contenu. L’interface initiale est en français. Une navigation simple par onglets « Groupes », « Activité » et « Profil » est retenue comme proposition.

## 7. Données conservées

| Ressource | Données principales | Règle |
|---|---|---|
| Utilisateur | nom d’affichage, courriel, hachage de mot de passe, date de création | Courriel unique; jamais exposer le hachage. |
| Session | utilisateur, empreinte du jeton de renouvellement, expiration, révocation | Rotation des jetons; révocation à la déconnexion de l’appareil. |
| Groupe | nom, devise XOF, créateur, membres et rôles, invitation hachée et expiration | Membres embarqués; accès vérifié sur le serveur. |
| Dépense | groupe, libellé, montant entier, payeur, parts, catégorie, date, note, auteur | Les parts sont embarquées; dépense reliée au groupe. |
| Règlement | groupe, émetteur, destinataire, montant, statut, date, auteur | En attente ou confirmé; entier positif. |

Les dépenses et règlements sont conservés dans des collections séparées et paginées. Les membres d’un groupe et les parts d’une dépense sont embarqués pour garder leurs données cohérentes. Index prévus : courriel unique; membre+date sur groupes; groupe+date sur dépenses et règlements; groupe+catégorie+date pour filtrer.

## 8. Architecture et règles techniques

- **Application :** Flutter/Dart, BLoC/Cubit, Clean Architecture orientée fonctionnalités. Le domaine ne dépend ni de Flutter ni du client HTTP. Les jetons sont dans le stockage sécurisé.
- **API :** Node.js 24+, TypeScript vérifié en CI, Express 5, Mongoose et MongoDB. Couches routes, contrôleurs, services et modèles.
- **Validation :** corps, paramètres et filtres sont validés par schéma (Zod ou équivalent); les champs inconnus sont rejetés/retirés selon une politique uniforme.
- **Authentification :** Argon2id ou bcrypt; accès court; renouvellement rotatif stocké haché; révocation par appareil.
- **Sécurité :** contrôle d’accès à chaque ressource, Helmet, limitation des tentatives d’authentification et d’invitation, taille de corps limitée, secrets uniquement en variables d’environnement, HTTPS en production.
- **API :** erreurs au format commun, statuts explicites, pagination plafonnée sur chaque liste, documentation des endpoints et requêtes d’exemple.
- **Qualité :** tests d’intégration API par ressource et tests d’autorisation; `bloc_test` sur chaque BLoC ayant de la logique; analyse Flutter propre et CI sur chaque pull request.

## 9. Hors périmètre V1 et point de conformité au cours

Hors V1 pour limiter le travail : paiements réels, conversion de devises, écritures hors ligne, reçus/photo de profil, recherche textuelle, analytics, mode anglais, notifications push et fonctions non décrites ci-dessus.

Cependant, le Project Book demande **au moins une** fonctionnalité avancée. Les réponses Q51 et Q52 indiquent « Oui » aux notifications et mises à jour en temps réel; Q9/Q10 indiquent français seul et Q11 indique aucun changement de langue. Pour tenir la demande « pas de fonctionnalités extra », la proposition est de **ne retenir qu’une seule option avancée**, vraisemblablement les mises à jour en temps réel, et de différer les notifications. Cette décision contredit le « oui » de Q51 et doit être confirmée par l’équipe/enseignant avant M1. Si aucune option avancée n’est acceptée, il faut demander une dérogation écrite au professeur.

## 10. Critères d’acceptation de la V1

- Un utilisateur peut s’inscrire, se connecter, renouveler sa session et se déconnecter.
- Un administrateur crée un groupe XOF et invite un autre compte avec un lien à usage unique.
- Un non-membre ne peut ni voir ni modifier les données du groupe, même en devinant son identifiant.
- Une dépense égale et une dépense personnalisée conservent des sommes de parts exactes; le cas avec reste est déterministe.
- L’API refuse les montants décimaux/négatifs, le payeur non membre, les participants non membres et les répartitions incorrectes.
- Les soldes sont calculés côté serveur et totalisent zéro avant et après un règlement confirmé.
- Les suggestions équilibrent les soldes et ne créent pas elles-mêmes de règlement.
- Les listes sont paginées et filtrables; l’historique récent reste visible à l’ouverture hors réseau.
- Les rôles d’accès sont testés; l’app montre des erreurs explicites et les quatre états de chargement.
- Une version Android de démonstration appelle l’API déployée en HTTPS.

## 11. Registre des réponses et hypothèses pour le questionnaire

**Légende :** « Réponse équipe » reproduit ou reformule la réponse fournie. « Proposition » complète une réponse vide. « En attente » signale une contradiction ou un choix qui exige une confirmation.

| N° | Décision intégrée |
|---:|---|
| 1 | Réponse équipe : les deux contextes sont visés (colocation et voyage). |
| 2 | Réponse équipe : colocataires prioritaires. |
| 3 | Réponse équipe : usage au moment de payer. |
| 4 | Réponse équipe : réduire l’oubli et le manque de transparence. |
| 5 | Proposition : démontrer une colocation; création d’un groupe, dépense à parts inégales, soldes, règlement confirmé. |
| 6 | Proposition : valider les parcours essentiels et zéro accès non autorisé dans les tests; critère de qualité plutôt qu’indicateur commercial. |
| 7 | Proposition : aucune application concurrente n’est requise comme référence; se concentrer sur la simplicité du parcours. |
| 8 | Réponse équipe : Android pour la première version. |
| 9 | Proposition selon Q10 : français seulement. En attente pour option avancée obligatoire. |
| 10 | Réponse équipe : français. |
| 11 | Réponse équipe : pas de changement de langue à chaud. |
| 12 | Réponse équipe : XOF. |
| 13 | Proposition : une seule devise par groupe; aucune conversion. |
| 14 | Proposition : XOF stocké comme entier en francs CFA, sans décimales. |
| 15 | Proposition : contraste lisible, tailles de texte système, libellés accessibles pour les contrôles. |
| 16 | Réponse équipe : inscription par courriel et mot de passe. |
| 17 | Réponse équipe : validation du courriel demandée; différée du socle V1 car elle requiert un service d’envoi. |
| 18 | Réponse équipe : administrateur. Interprétation : créateur administrateur du groupe. |
| 19 | Réponse équipe : l’administrateur gère les dépenses du groupe. |
| 20 | Réponse équipe : non, tous les membres ne peuvent pas ajouter des dépenses. En attente : confirmer si seul l’administrateur peut en créer. |
| 21 | Réponse équipe : invitation par lien. |
| 22 | Réponse équipe : lien à usage unique. |
| 23 | Réponse équipe : un utilisateur peut appartenir à plusieurs groupes. |
| 24 | Réponse équipe : un membre peut quitter ou être retiré; sa visibilité historique est limitée et détaillée dans Q25/Q26. |
| 25 | Réponse équipe : l’administrateur peut quitter le groupe; proposition : transférer le rôle avant départ. |
| 26 | Réponse équipe : groupe fermé consultable en lecture seule; suppression des données à fixer selon la politique de conservation. |
| 27 | Réponse équipe : montant, payeur, catégorie, date, participants, libellé et note. |
| 28 | Réponse équipe : payeur inclus parmi les participants; il ne paie pas pour un participant exclu de la dépense. |
| 29 | Réponse équipe : une dépense peut concerner un sous-groupe. |
| 30 | Réponse équipe : le reste du partage égal est attribué par ordre alphabétique. |
| 31 | Réponse équipe : possibilité d’exclure un membre selon la dépense/catégorie. |
| 32 | Réponse équipe : parts personnalisées saisies en montants. |
| 33 | Proposition : pas d’unités ou de pondérations séparées en V1; les montants personnalisés suffisent. |
| 34 | Réponse équipe : catégories personnalisées possibles; administrateur responsable de leur gestion. |
| 35 | Réponse équipe : date du jour par défaut; format français jour/mois/année. |
| 36 | Réponse équipe : photo de reçu souhaitée; reportée de la V1 pour éviter l’extension téléversement/stockage. |
| 37 | Réponse équipe : administrateur et payeur peuvent modifier/supprimer une dépense. |
| 38 | Proposition : aucune modification après qu’un règlement lié est confirmé; préserver le calcul plutôt qu’effacer une dette réglée. |
| 39 | Proposition : pas de dépenses récurrentes en V1. |
| 40 | Proposition : solde positif = le groupe doit à la personne; négatif = la personne doit au groupe. |
| 41 | Proposition : recalcul à la demande côté serveur, car la taille de la V1 est limitée; aucun solde client ne fait autorité. |
| 42 | Proposition : suggestions nettes de transferts entre débiteurs et créditeurs, en réduisant le nombre de transferts. |
| 43 | Proposition : oui, une suggestion peut porter sur la dette nette globale; montants bornés par le solde. |
| 44 | Réponse équipe : confirmation du règlement par son destinataire. |
| 45 | Proposition : uniquement enregistrer un paiement effectué hors app; aucun fournisseur de paiement. |
| 46 | Proposition : règlement partiel autorisé; pas d’édition après confirmation. |
| 47 | Proposition : afficher « Règlement enregistré — paiement effectué hors de BudgetBox ». |
| 48 | Réponse équipe : filtres membre, catégorie, période, payeur et type d’opération. |
| 49 | Proposition : récent d’abord, 20 éléments/page et maximum de 50 côté API. |
| 50 | Proposition : recherche texte différée; filtres suffisent pour V1. |
| 51 | Réponse équipe : notifications souhaitées; hors V1 proposée et en attente du choix avancé. |
| 52 | Réponse équipe : mises à jour en temps réel souhaitées; en attente du choix de l’unique option avancée. |
| 53 | Réponse équipe : consultation du dernier historique mis en cache hors réseau; pas d’écriture hors ligne. |
| 54 | Réponse équipe : nom d’affichage et photo; photo différée avec l’upload. |
| 55 | Réponse équipe : seuls les groupes auxquels la personne appartient sont visibles. |
| 56 | Proposition : garder auteur et dates de création/modification; pas d’audit complet avant/après en V1. |
| 57 | Proposition : aucune durée de conservation définie; un compte ne peut pas supprimer un groupe partagé sans transfert/confirmation. À valider. |
| 58 | Réponse équipe : pas de limite d’usage fonctionnelle; les tentatives de code seront néanmoins limitées côté serveur pour éviter le brute force. |
| 59 | Réponse équipe : déconnexion de l’appareil courant seulement. |
| 60 | Proposition : deux comptes de démonstration au minimum, un administrateur et un membre; aucun secret de production dans le dépôt. |
| 61 | Réponse équipe : identité visuelle à choisir; proposition sobre et lisible, avec couleur principale unique et contraste accessible. |
| 62 | Proposition : navigation « Groupes », « Activité », « Profil ». |
| 63 | Réponse équipe : page d’accueil après connexion. |
| 64 | Proposition : écran vide avec explication courte et bouton pour créer/rejoindre un groupe ou ajouter la première dépense selon le contexte. |
| 65 | Réponse équipe : message d’erreur explicite, avec réessai pour erreur réseau. |
| 66 | Proposition : données de démo d’une colocation avec 3–5 personnes, dépenses réalistes en XOF et un règlement partiel. |
| 67 | Proposition : démonstration sur deux comptes/appareils; l’admin invite, le membre ajoute/consulte selon le rôle final, puis règlement confirmé. |
| 68 | En attente : les cinq noms, compétences et disponibilités ne sont pas renseignés. |
| 69 | Proposition : membre 1 (toi) est lead technique d’après la demande de plus grande part; rôle officiel à confirmer par l’équipe. |
| 70 | Réponse équipe : thème 13 réservé/validé. |
| 71 | Réponse équipe : membre 2 gère le dépôt. |
| 72 | Proposition : GitHub, branches, petites pull requests, revue par un autre membre et tableau GitHub Projects. |
| 73 | Réponse équipe : chaque personne contribuera au code de l’API et de l’application. |
| 74 | En attente : choisir le téléphone Android réel et qui peut produire/installer l’APK. |
| 75 | Proposition : dépôt GitHub, MongoDB Atlas et hébergeur HTTPS; les comptes et plans disponibles restent à confirmer. |
| 76 | Proposition : point d’avancement hebdomadaire, revue de chaque PR avant fusion et acceptation par le responsable métier. |
| 77 | Proposition : toute suppression/modification d’exigence du Project Book ou du sujet T13 doit être approuvée par l’enseignant avant M1. |

## 12. Points à confirmer avant de figer M1

1. Choisir l’unique fonctionnalité avancée exigée par le livre, ou demander une dérogation. Les réponses actuelles souhaitent notifications et temps réel, mais la demande de départ exclut les extras.
2. Confirmer si seul l’administrateur crée les dépenses (Q20) ou si tous les membres peuvent en ajouter.
3. Confirmer si la vérification du courriel (Q17), les photos de reçus/profil (Q36/Q54) et les notifications (Q51) sont repoussées après la V1 de base.
4. Renseigner les cinq noms, rôles, disponibilités et l’appareil Android de démonstration.
5. Valider la politique de départ d’un administrateur, de conservation des groupes et de correction d’une opération après règlement.
