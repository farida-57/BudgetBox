# Contribution membre 4 — règlements et historique

## Périmètre livré

- `POST /api/v1/groups/:groupId/settlements` enregistre un règlement `pending`; le paiement est externe à BudgetBox.
- `POST /api/v1/groups/:groupId/settlements/:id/confirm` est réservé au destinataire et utilise une mise à jour atomique pour éviter une double confirmation.
- `GET /api/v1/groups/:groupId/settlements` liste les règlements, avec pagination et filtre de membre/période.
- `GET /api/v1/groups/:groupId/activity` renvoie dépenses et règlements triés ensemble, paginés et filtrables par type, membre, catégorie, payeur et période.
- Flutter : formulaire d’enregistrement, confirmation d’un règlement en attente, états chargement/vide/erreur et filtres de l’activité.

## Contrat de données provisoire

Règlement : `groupId`, `fromUserId`, `toUserId`, `amount` entier positif, `currencyCode`, `recordedBy`, `status` (`pending` ou `confirmed`), `confirmedAt`, `createdAt`, `updatedAt`.

Les dépenses sont supposées avoir `groupId`, `payerId`, `amount`, `participants: [{ userId, shareAmount }]`, `category` et `spentAt`. Les groupes sont supposés avoir `members` (identifiants ou objets avec `userId`) et `currencyCode`. Aligner ces champs avec les modèles des membres 2 et 3 avant la fusion.

## Authentification / intégration

Le routeur attend `req.user.id` issu du middleware JWT. Le petit bootstrap de ce dépôt utilise temporairement l’en-tête `X-User-Id` pour pouvoir raccorder le module avant l’arrivée du membre 2. Cet adaptateur est **réservé au développement local** et doit être remplacé par le middleware JWT avant déploiement. Le client Flutter offre le même champ de développement.

Le service reçoit `SettlementContext` pour les contrôles de membre, la devise et le montant maximal autorisé. L’adaptateur initial recalcule les soldes depuis les dépenses et règlements; le membre 1 doit relire cette convention et confirmer le traitement des règlements en attente dans la dette disponible. Le modèle d’argent du projet interprète les soldes depuis les opérations, sans jamais accepter un solde envoyé par le client.

## Filtres de l’activité

`page` démarre à 1; `limit` vaut 20 par défaut et est plafonné à 50. `from` et `to` sont des dates ISO. `type` vaut `expense` ou `settlement`. `memberId` cible payeur/participant pour une dépense et émetteur/destinataire pour un règlement. `category` et `payerId` s’appliquent aux dépenses.

## Étapes de raccordement à l’équipe

1. Membre 2 remplace l’adaptateur `X-User-Id` par son middleware JWT.
2. Aligner `Group` et `Expense` avec les schémas définitifs (ou injecter les modèles partagés dans `SettlementContext`).
3. Membre 1 valide la convention de signe et le plafond de dette, en particulier les règlements en attente et les dettes entre plusieurs membres.
4. Membre 3 valide les champs d’une dépense utilisés par l’activité.
5. Le widget d’entrée reçoit le `groupId` et l’utilisateur depuis la navigation protégée lorsque ces écrans sont disponibles.
