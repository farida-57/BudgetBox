# État d'intégration du projet

Cette branche d'intégration part du `main` actuel et rassemble les fonctionnalités déjà livrées par l'équipe : authentification/groupes, calcul des soldes, dépenses, règlements et historique. Elle reprend les commits de création/liste des dépenses et du formulaire Flutter, puis ajoute les liaisons de navigation, la configuration Edge et les contrôles CI.

## Parcours inclus

- Authentification et groupes avec invitations.
- Création/liste paginée de dépenses et formulaire de parts égales/personnalisées.
- Soldes nets et suggestions, calculés côté API.
- Saisie/confirmation des règlements et historique unifié filtrable.
- Configuration Flutter Web/Edge et GitHub Actions.

## Règle à faire valider par l'équipe

La réponse au questionnaire (Q20) est « Non » à la question de savoir si tous les membres peuvent créer dépenses et règlements. L'API limite provisoirement la création des dépenses aux administrateurs et l'application n'affiche le formulaire qu'à eux. Le PRD initial proposait au contraire de laisser tout membre ajouter une dépense : l'équipe doit confirmer quelle interprétation retenir avant la démonstration.

## Livraison à compléter par l'équipe

Les tests et compilations locales vérifient le code, mais ne remplacent pas la validation fonctionnelle avec une vraie instance MongoDB, les captures d'écran, l'APK installé sur un appareil, ni les livrables de rapport/présentation du cours. La clé JWT de production et une URI MongoDB réelle doivent rester dans des variables sécurisées.

## Décision métier encore à confirmer

Les règlements en attente réservent provisoirement une partie de la dette disponible, afin d'empêcher plusieurs paiements en attente de dépasser la dette nette. Le calcul n'inclut dans les soldes définitifs que les règlements confirmés. Valider cette règle avec l'équipe avant la livraison.
