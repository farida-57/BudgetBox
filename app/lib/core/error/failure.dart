/// Erreurs métier de l'application, mappées depuis les réponses API.
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Le serveur a répondu avec une erreur (4xx/5xx).
class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    this.statusCode,
    this.code,
  });

  final int? statusCode;
  final String? code;
}

/// Le serveur est injoignable (réseau coupé, timeout, DNS).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Impossible de joindre le serveur. Vérifiez votre connexion.']);
}

/// Erreur inattendue non classifiée.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Une erreur inattendue est survenue.']);
}
