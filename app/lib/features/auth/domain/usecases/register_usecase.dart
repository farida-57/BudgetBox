import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({
    required String displayName,
    required String email,
    required String password,
  }) =>
      _repository.register(displayName: displayName, email: email, password: password);
}
