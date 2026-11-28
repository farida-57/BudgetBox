# BudgetBox - application Flutter

## Prérequis

- Flutter/Dart correspondant aux versions indiquées dans `pubspec.yaml`.
- API BudgetBox démarrée sur le même ordinateur, port 3000.

## Démarrer dans Edge

Dans un premier terminal, démarre l'API depuis la racine du dépôt :

```powershell
cd api
Copy-Item .env.example .env # à faire une seule fois, puis configurer MongoDB et JWT_ACCESS_SECRET
npm ci
npm run dev
```

Dans un second terminal :

```powershell
cd app
flutter pub get
flutter run -d edge
```

Sur le web, l'application utilise `http://localhost:3000/api/v1` par défaut. Une autre adresse peut être fournie avec `--dart-define=BUDGETBOX_API_URL=https://.../api/v1`. L'API doit autoriser l'origine du navigateur dans `CORS_ORIGIN`.

Pour Android Emulator, l'adresse par défaut est `http://10.0.2.2:3000/api/v1`. En production, fournir une URL HTTPS avec le même `--dart-define`.

## Contrôles

```powershell
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```
