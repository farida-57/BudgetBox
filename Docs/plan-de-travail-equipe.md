# Plan de travail de l’équipe BudgetBox

**Version 1.0 — répartition opérationnelle**  
Ce document transforme le cahier des charges BudgetBox en tâches, responsables, procédures de travail, outils et livrables pour cinq personnes. Membre 1 désigne la personne qui a demandé la plus grande part; membre 2 est le propriétaire du dépôt selon le questionnaire. Les noms restent à remplir.

## 1. Répartition de la charge

| Membre | Part indicative | Rôle principal | Livrables dont il est responsable |
|---|---:|---|---|
| **Membre 1 — toi** | **30 %** | Lead technique, règles financières, intégration des fonctionnalités | Décisions d’architecture, services de calcul des parts/soldes/suggestions, tests de ces règles, domaine/app BLoC des soldes, intégration finale et explications techniques. |
| Membre 2 | 18 % | Administrateur du dépôt, authentification et groupes | Dépôt Git, auth/session, groupes, membres, invitations à usage unique, écrans d’authentification et navigation protégée. |
| Membre 3 | 18 % | Dépenses, répartition et catégories | API de création/validation de dépense, modèle des parts, formulaire mobile égal/personnalisé, champs et erreurs 422, tests. |
| Membre 4 | 18 % | Règlements et historique | API d’enregistrement/confirmation de règlement, filtres et pagination, écrans de règlement et historique, tests d’accès. |
| Membre 5 | 16 % | Qualité, interface transverse, CI et release | États d’interface, cache en lecture, validation/analyse et CI, données de démo, build Android, documentation de démarrage. |

La part de Membre 1 est la plus importante, comme demandé, mais les calculs financiers doivent être présentés à l’équipe et relus par Membre 4. Chaque personne écrit du code dans **les deux côtés**, API et Flutter, même si son rôle principal est spécialisé. Un partage des responsabilités ne doit pas créer un silo où une seule personne saurait expliquer une fonctionnalité.

### Contributions croisées obligatoires

| Membre | API qu’il code | Application Flutter qu’il code |
|---|---|---|
| 1 | Calculs dépense/solde/suggestions et leurs tests | Contrats de domaine, cas d’usage/BLoC des soldes et intégration du parcours financier |
| 2 | Authentification, sessions, groupes et invitations | Inscription/connexion, stockage sécurisé, groupes, navigation protégée |
| 3 | Validation et endpoints de dépense avec parts | Formulaire, choix des participants, répartition, affichage erreurs API |
| 4 | Règlements, confirmation et endpoints d’historique | Saisie/confirmation de règlement, listes et filtres |
| 5 | Middleware sécurité/validation, seed et configuration avec revue | Cache lecture, états génériques, configuration, analyse et tests d’intégration UI |

Pour la fonctionnalité avancée, son propriétaire ne sera nommé qu’après arbitrage avec l’équipe et l’enseignant. Aucun membre ne commence un module avancé non validé.

## 2. Tâches précises par membre

### Membre 1 — lead technique et calculs financiers (30 %)

1. Relire les règles du cahier des charges et les convertir en exemples chiffrés : égalité avec reste, partage personnalisé, dépenses multi-participants, règlement partiel.
2. Dessiner/valider le modèle de calcul : solde positif signifie « le groupe doit à la personne »; négatif signifie « elle doit au groupe »; somme des soldes égale à zéro.
3. Développer le service API de calcul des parts égales et personnalisées, des soldes et des propositions de règlement.
4. S’assurer qu’aucun endpoint ne reçoit de solde calculé comme valeur de référence depuis le mobile.
5. Écrire les tests API ciblant sommes, entiers, membres, restes et conservation de la somme nulle.
6. Créer les entités/domain, interfaces de repository et cas d’usage de lecture des soldes côté Flutter.
7. Relire les PR de Membre 3 ou 4 sur le contrat entre API et app; coordonner l’intégration et les conflits.
8. Expliquer le calcul à chaque membre et participer au scénario de défense.

**Ne pas prendre seul :** l’authentification ou toutes les tâches de revue. Le lead doit déléguer, garder des PR petites et faire tourner les explications.

### Membre 2 — propriétaire du dépôt, comptes et groupes (18 %)

1. Créer le dépôt monorepo, protéger `main`, inviter l’enseignant et configurer les issues/étiquettes.
2. Définir les conventions de branches, commits, PR et variables d’environnement avec l’équipe.
3. Développer inscription, connexion, renouvellement rotatif et déconnexion sur l’API; ajouter hachage mot de passe et tests d’accès.
4. Développer groupes, adhésion, rôles et invitation par lien à usage unique; permettre plusieurs groupes par utilisateur.
5. Ajouter les gardes d’accès pour groupe/membres et les tests d’un non-membre.
6. Développer les écrans Flutter d’inscription/connexion, la persistance sécurisée des jetons et la navigation protégée.
7. Documenter les paramètres de configuration dans `.env.example`; aucun secret réel dans ce fichier.
8. Maintenir README et tableau des tickets; ne pas fusionner sa propre PR sans revue.

### Membre 3 — dépenses et répartition (18 %)

1. Développer le modèle API de dépense et validation des champs : montant entier, catégorie, date, payeur, participants et parts.
2. Implémenter la règle d’accès de création qui sera confirmée pour Q20.
3. Implémenter création de dépense égale et personnalisée via le service; assurer les checks d’appartenance.
4. Ajouter endpoint paginé et filtre de liste utile à l’historique avec revue de Membre 4.
5. Construire le formulaire Flutter : choix des membres participants, partage égal, saisie de montants personnalisés, note et catégorie.
6. Afficher la somme courante et les erreurs 422 près des champs; la validation serveur reste la règle finale.
7. Écrire tests de service et BLoC/Cubit pour succès, erreur, somme fausse et membre absent.
8. Ne pas ajouter photo de reçu en V1 tant que cette extension n’est pas confirmée.

### Membre 4 — règlements et historique (18 %)

1. Implémenter les règlements en attente/confirmés et le contrôle que les deux personnes sont membres du groupe.
2. Empêcher l’auto-confirmation par le destinataire et tout montant non entier ou supérieur au solde autorisé.
3. Ajouter endpoints de règlement, de consultation de l’historique et de filtres/pagination.
4. Écrire tests d’autorisation, règlement partiel, confirmation et recalcul de solde avec Membre 1.
5. Construire écrans d’enregistrement et de confirmation; afficher clairement que le paiement est fait hors de l’application.
6. Construire l’historique récent, filtres membre/catégorie/période/payeur/type et état vide/erreur/réessai.
7. Valider que les suggestions n’écrivent aucun règlement d’elles-mêmes.
8. Documenter les routes d’API dans le tableau des endpoints et les requêtes exemples.

### Membre 5 — qualité, intégration et release (16 %)

1. Développer côté API configuration validée au démarrage, gestion d’erreurs commune et middleware de sécurité avec revue croisée.
2. Ajouter génération de données réalistes pour la démonstration et comptes de test non sensibles.
3. Développer côté app le cache lecture de l’historique et les états génériques chargement/vide/erreur/contenu.
4. Configurer CI : type-check/tests API, format/analyse/tests Flutter sur chaque PR.
5. Maintenir les variables de configuration documentées, sans secrets réels dans Git.
6. Vérifier `flutter analyze`, lint/typecheck backend, build Android et procédure README sur une machine propre.
7. Créer l’APK release et vérifier son installation sur un téléphone Android réel.
8. Coordonner les captures d’écran et la préparation technique de la démo; produire la présentation PowerPoint uniquement à la fin, avec toute l’équipe.

## 3. Arborescence de fichiers attendue

```text
budgetbox/
├── api/
│   ├── src/
│   │   ├── app.ts
│   │   ├── server.ts
│   │   ├── config/                 # environnement validé au démarrage
│   │   ├── shared/                 # erreurs, auth, validation, pagination
│   │   └── modules/
│   │       ├── auth/               # routes, controllers, services, models
│   │       ├── users/
│   │       ├── groups/
│   │       ├── expenses/
│   │       ├── balances/
│   │       └── settlements/
│   ├── test/                       # tests API intégration + autorisation
│   ├── requests.http               # appels d’exemple
│   ├── .env.example                # noms des variables, aucune valeur secrète
│   └── package.json
├── app/
│   ├── lib/
│   │   ├── app/                    # bootstrap, routes, injection
│   │   ├── core/                   # HTTP, stockage sécurisé, Result/Failure
│   │   └── features/
│   │       ├── auth/{data,domain,presentation}/
│   │       ├── groups/{data,domain,presentation}/
│   │       ├── expenses/{data,domain,presentation}/
│   │       ├── balances/{data,domain,presentation}/
│   │       └── settlements/{data,domain,presentation}/
│   ├── test/                       # tests de BLoC/Cubit et logique
│   └── pubspec.yaml
├── docs/
│   ├── cahier-des-charges.md
│   ├── plan-de-travail-equipe.md
│   ├── design.pdf                  # 6 à 10 pages pour M1
│   ├── report.pdf                  # 10 à 15 pages pour M4
│   ├── slides.pptx                 # présentation modifiable demandée
│   ├── slides.pdf                  # export pour les consignes du cours
│   ├── uml/                        # sources de diagrammes
│   └── screenshots/
├── .github/workflows/ci.yml
└── README.md
```

Dans l’application, chaque fonctionnalité possède `domain` (entités, contrats, cas d’usage), `data` (DTO, sources et repositories) et `presentation` (pages, widgets, BLoC). Le code du domaine ne dépend pas de Flutter ou Dio. Dans l’API, une route valide puis appelle un controller; le controller délègue la règle au service; le service utilise le modèle Mongoose et retourne une réponse au format commun.

## 4. Outils à utiliser et accès nécessaires

| Outil | Qui l’utilise | Utilité et moment |
|---|---|---|
| Flutter / Dart | Membres 1–5 | Application Android; setup et build M2–M4. |
| `flutter_bloc`, `bloc_test` | Membres app 1–5 | État métier des écrans et tests de BLoC; aucune logique métier dans les widgets. |
| `go_router` | Membre 2, revu par 1 | Routes privées et redirection selon l’authentification. |
| `flutter_secure_storage` | Membre 2 | Jetons conservés dans le stockage Android sécurisé. |
| Node.js 24+, TypeScript | Membres API 1–5 | API typée; version et type-check dans CI imposés par le Project Book. |
| Express 5 | Membres API 1–5 | Routes et middleware REST. |
| MongoDB + Mongoose | Membre 2/3/4, revu par 1 | Collections, relations, validation et persistance. |
| Zod (ou équivalent) | Membre 3/5 | Validation stricte des corps, paramètres, filtres et champs inconnus. |
| GitHub | Membre 2 gère le dépôt; tous contribuent | Branches, PR relues, tickets, actions CI. L’équipe répond que le thème est réservé et Membre 2 a le dépôt. |
| GitHub Actions | Membre 5, revue de toute l’équipe | Vérifications à chaque PR pour empêcher une régression. |
| MongoDB Atlas | Membre 2 crée/configure; membre 5 suit le déploiement | Base distante de démonstration. Compte et accès requis seulement pour M2/M4. |
| Hébergeur HTTPS | Membre 5, membre 2 administre les secrets | API déployée; plateforme à choisir selon comptes/quotas réellement disponibles. |
| Android Studio / appareil Android | Membre 5 pilote, tous testent | Émulateur, génération et vérification APK sur téléphone réel. Appareil encore à confirmer. |
| PlantUML | Membre 1 maintient, tous relisent | Sources `.puml` de l’architecture et séquences; rendu en image facultatif pour le rapport. |
| Bruno/Postman/`requests.http` | Membres 2–4 | Vérifier les endpoints à la main; documenter les exemples sans secrets. |

### Accès ou actions manuelles à prévoir

- **Dès M0 :** le propriétaire (Membre 2) crée le dépôt et invite les quatre autres et l’enseignant; il active les protections de branche/PR et Actions.
- **Avant M2 :** un membre crée un compte MongoDB Atlas, crée une base et garde la chaîne de connexion dans les secrets de déploiement, pas dans les documents ou le dépôt.
- **Avant M2 :** choisir un hébergeur et créer ses variables secrètes; l’API doit être accessible en HTTPS.
- **Avant M4 :** installer l’APK sur un téléphone Android réel; fournir l’accès/autorisation USB ou partager l’APK avec la personne qui fera la démo.
- **Seulement si le groupe réactive les fonctions repoussées :** service SMTP/email pour vérification d’adresse; stockage d’objets et accès de téléversement pour reçus/photos; fournisseur de notifications si push retenu. Ces accès ne sont pas requis par le socle actuel.

## 5. Procédure quotidienne de travail

1. **Ticket :** une tâche correspond à une petite fonctionnalité ou règle testable; elle a un responsable, une personne de revue, les critères d’acceptation et le côté API/app.
2. **Branche :** créer `feature/<courte-description>` depuis la branche principale; une branche = une PR petite et lisible.
3. **Contrat :** avant le code app+API, définir méthode/route, champs, erreurs, statut HTTP et exemple JSON dans le ticket ou le README.
4. **Implémentation :** développer une tranche verticale (API et écran) ou convenir avec le binôme du contrat exact. Toute règle d’argent ou de droit s’exécute sur l’API.
5. **Vérifications locales :** format, lint/type-check et tests du module; vérifier erreur/chargement/vide/succès pour l’écran.
6. **Pull request :** décrire changement, capture éventuelle, test manuel, risques et ticket; demander revue à une autre personne.
7. **Revue :** vérifier les autorisations, entiers monétaires, champs secrets, erreurs, test couvrant le cas nominal et invalide; demander correction avant approbation.
8. **CI et fusion :** fusion seulement après CI verte et revue; pas de push direct sur `main` après M1, comme l’exige le livre.
9. **Apprentissage :** l’auteur explique à un autre membre ce qu’il a fait et pourquoi. Toute aide d’IA est revue, testée, comprise et déclarée dans le rapport final.
10. **Fin de semaine :** mise à jour du board, démo interne, note d’avancement (fait, retard, blocage), tag du jalon lorsqu’il est accepté.

## 6. Ordre de réalisation et jalons du cours

| Échéance du livre | Tâches BudgetBox | Responsable principal | Preuve que le jalon est atteint |
|---|---|---|---|
| Semaine 1 — M0 | Confirmer le thème, les cinq membres, dépôt et invitations; rôles et board | Membre 2 + équipe | Dépôt partagé, professeur invité, thème enregistré. |
| Fin semaine 2 — M1 | Finaliser cahier des charges, 10–20 user stories, modèle et index, endpoints/droits, maquettes, diagrammes, risques | Membre 1 coordonne; chacun rédige sa partie | `docs/design.pdf` de 6–10 pages relu et validé par l’équipe. |
| Fin semaine 4 — M2 | Auth complète, un groupe visible dans l’app, CI, API distante | Membre 2 + Membre 5 | Register/login/refresh/logout, route privée et liste groupe contre API déployée. |
| Fin semaine 6 — M3 | Dépenses, répartitions, soldes, suggestions, règlement/historique; tests et filtres | Membres 1/3/4 | Tous les critères V1 passés; règles d’accès testées pour chaque ressource. |
| Fin semaine 7 — M4 | Fonctionnalité avancée retenue, APK, données démo, rapport, présentation, vidéo | Membre 5 coordonne; équipe entière produit | Release candidate `v1.0.0`, app téléphone, rapport 10–15 pages, PowerPoint/PDF, vidéo ≤3 min, code gelé. |
| Semaine 8 — défense | Installation, présentation, démonstration deux rôles, réponses individuelles | Tous | 3 min setup, 7 min slides, 7 min démo, 8 min questions. |

Le cours prévoit que manquer un jalon coûte des points; publier tôt les retards et blocages. Les dates exactes sont données par l’enseignant.

## 7. Ordre des PR et dépendances

1. **Base technique** (Membres 2 et 5, revue Membre 1) : structure API/app, config, lint, CI minimale.
2. **Auth** (Membre 2, revue Membre 5) : utilisateur, session, endpoints, stockage sécurisé, route protégée.
3. **Groupes** (Membre 2, revue Membre 1) : création, lien d’invitation, adhésion, droits et tests membre/non-membre.
4. **Dépenses** (Membre 3, revue Membre 1) : contrat API, modèle, parts, formulaire et tests d’égalité/personnalisé.
5. **Soldes** (Membre 1, revue Membre 4) : calcul serveur, endpoint, écran et test somme nulle.
6. **Règlements/historique** (Membre 4, revue Membre 3) : statut/confirmation, pagination/filtre et écrans.
7. **Cache lecture et finition** (Membre 5, revues tournantes) : cache puis réseau, messages, seed, accessibilité de base, build.
8. **Option avancée et release** : démarrer uniquement après arbitrage écrit de l’option avancée et validation du reste du socle.

## 8. Tests et définition de « terminé »

### Tests API requis

- Authentification : inscription, mauvais mot de passe, refresh rotatif, logout/revocation.
- Autorisation : membre A accède à son groupe; utilisateur B ne lit/modifie pas groupe A; lien expiré ou réutilisé refusé.
- Dépenses : montant valide, total de parts incorrect, montant décimal/négatif, payeur/participant hors groupe, partage égal avec reste.
- Soldes : dépenses puis règlement; soldes entiers; somme du groupe égale zéro; suggestion n’écrit rien.
- Règlements : partiel, montant excessif, destinataire confirme, non-destinataire tente confirmation.
- Listes : pagination plafonnée, filtres validés, tri stable.

### Tests application requis

- Un `bloc_test` pour chaque BLoC/Cubit contenant de la logique, succès et échec.
- Formulaire présente les erreurs du serveur près des champs.
- Les écrans de liste couvrent chargement/vide/erreur/réessai/contenu.
- Cache affiche les dernières données pendant la première tentative réseau hors ligne.
- Le guard route redirige vers login sans session valide.

### Definition of done par ticket

- Critères d’acceptation démontrés; la règle serveur n’est pas doublée comme autorité dans un widget.
- Tests ajoutés ou mise à jour avec le code; format/lint réussis.
- Endpoint documenté; aucun secret/donnée réelle committé.
- PR revue et CI verte; responsable et relecteur capables d’expliquer le changement.

## 9. Risques de coordination

- Ne pas commencer tous les écrans avant l’auth et l’API minimum; la marche M2 attend un parcours traversant toute la pile.
- Les permissions Q20 et l’option avancée ne sont pas encore arbitrées; éviter de coder une hypothèse coûteuse.
- Les calculs doivent être compris par les cinq personnes, pas seulement par leur auteur.
- Les réponses Q17, Q36, Q51, Q52 et Q54 impliquent e-mail, fichiers ou événements en direct. Les reporter au-delà de V1 tant que leur inclusion n’est pas explicitement confirmée.
- Le membre 2 contrôle l’accès au dépôt; un plan de sauvegarde/relève doit être décidé pour éviter un blocage de toute l’équipe.
