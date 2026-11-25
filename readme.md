# BudgetBox

**BudgetBox** est une application mobile de gestion des dépenses partagées. Elle permet à plusieurs personnes de gérer leurs dépenses au sein de groupes, de répartir les coûts entre les participants, de suivre les soldes et d'enregistrer les règlements.

L'objectif est de simplifier la gestion des dépenses communes et d'assurer un suivi transparent des contributions de chaque membre.

> **Statut du projet :** En cours de développement — Version 1.0

---

## 1. Fonctionnalités principales

### Authentification et gestion des utilisateurs
- Inscription et connexion des utilisateurs.
- Gestion des sessions.
- Renouvellement des jetons d'authentification.
- Déconnexion sécurisée.
- Navigation protégée.

### Gestion des groupes
- Création de groupes.
- Ajout et adhésion de membres.
- Gestion des rôles.
- Invitation de membres par lien à usage unique.
- Possibilité pour un utilisateur d'appartenir à plusieurs groupes.

### Gestion des dépenses
- Création de dépenses.
- Désignation du payeur.
- Sélection des participants.
- Répartition égale ou personnalisée des dépenses.
- Gestion des catégories et des dates.
- Consultation des dépenses.

### Gestion des soldes
- Calcul des parts de chaque membre.
- Consultation des soldes individuels et collectifs.
- Proposition de règlements pour équilibrer les comptes.

### Gestion des règlements et historique
- Enregistrement des règlements.
- Confirmation des règlements.
- Gestion des paiements partiels.
- Consultation de l'historique.
- Filtrage par membre, catégorie, période, payeur et type.

---

## 2. Technologies utilisées

### Application mobile
- **Flutter** : développement de l'application mobile.
- **Dart** : langage de programmation.
- **flutter_bloc** : gestion des états.
- **go_router** : navigation.
- **flutter_secure_storage** : stockage sécurisé des jetons.

### Backend
- **Node.js** : environnement d'exécution JavaScript.
- **TypeScript** : développement backend typé.
- **Express 5** : création de l'API REST.
- **MongoDB** : base de données NoSQL.
- **Mongoose** : gestion des modèles et interactions avec MongoDB.
- **Zod** : validation des données.

### Outils de développement
- Git et GitHub : gestion du code source et collaboration.
- GitHub Actions : intégration continue.
- Postman / Bruno : tests des endpoints API.
- PlantUML : réalisation des diagrammes UML.

---

## 3. Architecture du projet

Le projet utilise une architecture monorepo. Le backend et l'application mobile sont regroupés dans un même dépôt Git.

```text
BudgetBox/
│
├── api/
│   ├── src/
│   │   ├── app.ts
│   │   ├── server.ts
│   │   ├── config/
│   │   ├── shared/
│   │   └── modules/
│   │       ├── auth/
│   │       ├── users/
│   │       ├── groups/
│   │       ├── expenses/
│   │       ├── balances/
│   │       └── settlements/
│   │
│   ├── test/
│   ├── requests.http
│   ├── .env.example
│   └── package.json
│
├── app/
│   ├── lib/
│   │   ├── app/
│   │   ├── core/
│   │   └── features/
│   │       ├── auth/
│   │       ├── groups/
│   │       ├── expenses/
│   │       ├── balances/
│   │       └── settlements/
│   │
│   ├── test/
│   └── pubspec.yaml
│
├── docs/
│   ├── cahier-des-charges.md
│   ├── plan-de-travail-equipe.md
│   ├── design.pdf
│   ├── report.pdf
│   ├── slides.pptx
│   ├── slides.pdf
│   ├── uml/
│   └── screenshots/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
└── README.md
```

### Organisation du backend

Le backend est organisé par modules fonctionnels :

- `auth` : authentification et gestion des sessions.
- `users` : gestion des utilisateurs.
- `groups` : groupes, membres et invitations.
- `expenses` : dépenses et répartition.
- `balances` : calcul des soldes.
- `settlements` : règlements et historique.

### Organisation de l'application Flutter

Chaque fonctionnalité est organisée en trois parties :

- `data` : sources de données, DTO et repositories.
- `domain` : entités, interfaces et cas d'utilisation.
- `presentation` : pages, widgets et gestion des états avec BLoC.

---

## 4. Installation et configuration

### Prérequis

Avant de commencer, installer :

- Node.js 24 ou une version compatible.
- Flutter et Dart.
- MongoDB ou un compte MongoDB Atlas.
- Git.
- Android Studio ou un appareil Android pour tester l'application.

### Cloner le dépôt

```bash
git clone https://github.com/farida-57/BudgetBox.git
```

Accéder au projet :

```bash
cd BudgetBox
```

### Configuration du backend

Accéder au dossier API :

```bash
cd api
```

Installer les dépendances :

```bash
npm install
```

Créer un fichier `.env` à partir du modèle :

```bash
cp .env.example .env
```

Renseigner les variables de configuration nécessaires dans `.env`, notamment la connexion à MongoDB et les paramètres d'authentification.

**Important :** les mots de passe, clés secrètes et chaînes de connexion réelles ne doivent jamais être publiés sur GitHub.

Les commandes exactes de lancement seront ajoutées selon les scripts définis dans `package.json`.

### Configuration de l'application Flutter

Depuis la racine du projet :

```bash
cd app
```

Récupérer les dépendances :

```bash
flutter pub get
```

Vérifier le projet :

```bash
flutter analyze
```

Lancer l'application :

```bash
flutter run
```

---

## 5. Sécurité

La sécurité fait partie des exigences du projet.

Les mesures prévues comprennent :

- Hachage des mots de passe.
- Gestion sécurisée des sessions et des jetons.
- Stockage sécurisé des jetons sur l'application mobile.
- Contrôle des droits d'accès aux groupes.
- Vérification de l'appartenance des utilisateurs aux groupes.
- Validation des données côté serveur.
- Protection des variables d'environnement et des informations sensibles.

---

## 6. Tests et qualité

Des tests seront réalisés sur les différentes fonctionnalités.

### Backend
- Tests d'inscription et de connexion.
- Tests de renouvellement et de révocation des sessions.
- Tests des droits d'accès.
- Tests de création et de répartition des dépenses.
- Tests des calculs de soldes.
- Tests des règlements.

### Application Flutter
- Tests des BLoC/Cubit.
- Tests des formulaires.
- Tests des états de chargement, de succès et d'erreur.
- Tests de navigation et de protection des routes.

L'intégration continue avec GitHub Actions permettra d'exécuter les vérifications nécessaires lors des contributions.

---

## 7. Collaboration

Le projet est développé en équipe à travers un dépôt GitHub partagé.

Chaque membre contribue au développement des fonctionnalités qui lui sont attribuées.

Les contributions passent par des commits et des Pull Requests afin de faciliter le suivi et la relecture du code.

Le dépôt commun permet à tous les membres de travailler sur le même projet.

---

## 8. Équipe du projet

**Groupe 13**

| Membre | Responsabilité principale |
|---|---|
| Membre 1 | Direction technique et calculs financiers |
| Membre 2 | Dépôt, authentification et groupes |
| Membre 3 | Dépenses et répartition |
| Membre 4 | Règlements et historique |
| Membre 5 | Qualité, intégration et release |

---

## 9. Objectif final

L'objectif est de fournir une application mobile fonctionnelle, sécurisée et facile à utiliser, permettant aux utilisateurs de gérer leurs dépenses communes, de suivre leurs soldes et de faciliter les règlements au sein de leurs groupes.

---

**Projet :** BudgetBox  
**Groupe :** 13  
**Groupe :** 13  
---

## 10. Lancer en local (backend + auth/groupes)

### API (`api/`)

```bash
cd api
cp .env.example .env   # puis remplir MONGODB_URI et JWT_ACCESS_SECRET
npm install
npm run dev            # http://localhost:3000/api/v1
```

Vérifications : `npm run typecheck` et `npm test` (tests API avec MongoDB en mémoire).

### Application (`app/`)

```bash
cd app
flutter pub get
flutter run -d <appareil> --dart-define=BUDGETBOX_API_URL=http://10.0.2.2:3000/api/v1
```

`10.0.2.2` est l'adresse de la machine hôte depuis l'émulateur Android ; sur un appareil physique, utiliser l'IP locale du PC.

Vérifications : `flutter analyze` et `flutter test`.

### Compte de test rapide

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"displayName":"Test","email":"test@example.com","password":"motdepasse123"}'
```
