abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erreur serveur. Vérifiez votre connexion.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erreur de stockage local.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Erreur d\'authentification.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Donnée introuvable.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Données invalides.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Erreur lors de l\'upload du fichier.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission refusée.']);
}
