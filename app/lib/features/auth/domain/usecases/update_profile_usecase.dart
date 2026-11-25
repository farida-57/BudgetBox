import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call(String displayName) => _repository.updateDisplayName(displayName);
}
