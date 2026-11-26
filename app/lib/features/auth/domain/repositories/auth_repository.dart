import '../entities/user.dart';

/// Contrat du repository d'authentification.
/// L'implémentation data gère la persistance sécurisée des jetons.
abstract class AuthRepository {
  /// Inscrit un utilisateur, persiste les jetons et retourne le profil.
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  });

  /// Connecte un utilisateur, persiste les jetons et retourne le profil.
  Future<User> login({required String email, required String password});

  /// Tente de restaurer la session via le refresh token.
  /// Retourne null si aucune session valide n'existe.
  Future<User?> restoreSession();

  /// Met à jour le nom d'affichage du profil.
  Future<User> updateDisplayName(String displayName);

  /// Révoque la session côté serveur puis efface les jetons locaux.
  Future<void> logout();
}
