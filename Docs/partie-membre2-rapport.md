BudgetBox — Rapport de projet

1. Ce que le produit fait

BudgetBox est une application mobile de partage de dépenses entre membres d'un même groupe (colocation, voyage, association). L'application est faite d'une API REST en Node.js, Express et MongoDB, et d'une application Flutter pour Android.

[CAPTURE : écran de connexion]

[CAPTURE : écran d'inscription]

[CAPTURE : liste des groupes]

[CAPTURE : création d'un groupe]

[CAPTURE : détail d'un groupe avec les membres]

[CAPTURE : écran d'acceptation d'invitation]


2. Architecture

Côté API, le code est organisé en couches pour chaque ressource : routes, contrôleurs, services et modèles. Les modules auth, users et groups suivent cette structure. Chaque erreur est renvoyée dans un format unique avec un code, un message et le détail des champs en erreur.

Côté application Flutter, chaque feature (auth, groups) est divisée en trois couches : domain (entités, use cases, contrats des repositories), data (sources distantes, modèles, implémentations) et presentation (cubits et écrans). Le domain n'importe ni Flutter ni Dio. Les erreurs sont converties en Failure une seule fois, à la frontière data. L'injection des dépendances est centralisée dans un seul fichier, et la navigation est déclarative avec go_router, protégée par l'état d'authentification.

Du code du lab, nous avons gardé la structure feature-first, le client HTTP Dio avec ses intercepteurs, le stockage sécurisé des jetons et le pattern Result/Failure. Nous avons adapté le module auth pour les sessions persistées en base avec rotation des jetons, et ajouté le rate limiting sur l'authentification.


3. Sécurité

Authentification : les mots de passe sont hachés avec bcrypt. L'authentification utilise deux jetons : un access token JWT valide 15 minutes, et un refresh token opaque stocké hashé en base et rotatif à chaque utilisation. Si un ancien refresh token est réutilisé, la session est détruite. La déconnexion révoque la session côté serveur et efface les jetons locaux. Toutes les entrées sont validées par des schémas Zod stricts.

Autorisation : un middleware JWT protège toutes les routes. Chaque requête sur un groupe vérifie que l'utilisateur en est membre. Dans un groupe, il y a deux rôles : admin et membre. Seul un admin peut créer une invitation, retirer un membre ou modifier le groupe. Le dernier admin ne peut pas être retiré. Les codes d'invitation sont hashés en base, à usage unique et expirent après 7 jours.

Protections : un rate limiting sur les routes d'authentification renvoie une erreur 429 après trop de tentatives. helmet et une limite de taille des corps sont appliqués sur toute l'API. Les secrets sont dans des variables d'environnement et le fichier .env n'est jamais commité.

Correspondance avec les risques OWASP API : le contrôle d'accès au niveau objet est assuré par la vérification d'appartenance au groupe ; l'authentification est assurée par bcrypt, les JWT courts et le refresh rotatif ; les rôles admin/membre sont appliqués par des middlewares ; le rate limiting et la pagination plafonnée limitent la consommation de ressources ; helmet, CORS restreint et l'absence de secrets dans Git évitent les erreurs de configuration.


4. State management

AuthCubit gère l'état global de session : AuthInitial, AuthLoading, AuthAuthenticated(user), AuthUnauthenticated. Il gère la restauration de session au démarrage, le login, le register, le logout et la mise à jour du profil. Le routeur écoute cet état : non connecté, l'utilisateur est redirigé vers l'écran de connexion ; connecté, il accède aux écrans des groupes. Côté réseau, sur un 401, le client tente une seule fois un refresh du jeton puis rejoue la requête.

GroupsCubit charge la liste des groupes de l'utilisateur et permet d'en créer un. GroupDetailCubit charge le détail d'un groupe et ses membres, et gère l'invitation et le retrait de membre. InvitationCubit gère l'acceptation d'un code d'invitation et les erreurs de lien invalide ou expiré. Chaque cubit émet des états loading, loaded et error, et chaque écran affiche des états distincts pour le chargement, la liste vide, l'erreur avec bouton réessayer, et le contenu.


5. Tests

Nous avons écrit des tests automatiques pour l'API qui simulent des appels avec une vraie base de données temporaire. Ils vérifient : l'inscription (succès, email déjà utilisé, données invalides), la connexion (succès, mauvais mot de passe), le refresh token (rotation, jeton révoqué), le logout, et pour les groupes : création, liste, détail, erreur 403 pour un non-membre, invitation réservée aux admins, code d'invitation à usage unique et expiré, dernier admin non retirable.

Côté application, nous avons testé les cubits avec des succès et des échecs : restauration de session, login réussi ou en erreur, chargement de la liste des groupes, création, détail d'un groupe, acceptation d'invitation valide ou invalide.

Ce qui n'est pas testé : les écrans eux-mêmes (boutons, affichage) ne sont pas testés automatiquement ; ils sont vérifiés manuellement sur l'émulateur. Un test de bout en bout complet avec l'API déployée reste à faire pour la version finale.


6. Décisions techniques

Première décision : nous aurions dû rendre la devise du groupe configurable dès la création (EUR, XOF, USD) au lieu de la fixer à XOF en dur, et brancher le formatage des montants dessus.

Deuxième décision : nous aurions dû afficher directement les détails des erreurs 422 à côté des champs du formulaire dès le départ, au lieu d'un message général.

Troisième décision : nous aurions dû prévoir un stockage des tokens avec une migration ou une versioning dès le début, pour faciliter un futur changement de stratégie de session.


7. Contribution individuelle

J'ai conçu et implémenté les modules authentification et groupes de BudgetBox, en full-stack. Côté API : inscription et connexion avec JWT et refresh token rotatif hashé, bcrypt, rate limiting, sessions révocables, CRUD des groupes, membres et rôles admin/membre, invitations à usage unique hashées avec expiration, validés par Zod et couverts par des tests d'intégration. Côté application Flutter : la feature auth (use cases, AuthCubit, écrans login/register/profil, stockage sécurisé des jetons, refresh automatique sur 401) et la feature groupes (use cases, cubits, écrans liste/création/détail/acceptation d'invitation), avec des tests de cubits. J'ai aussi corrigé le flux de session, ajouté l'affichage des erreurs de validation détaillées et l'œil afficher/masquer sur les mots de passe.
