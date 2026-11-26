import '../../../../core/error/failure.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_payload_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, this._tokenStorage);

  final AuthRemoteDataSource _dataSource;
  final TokenStorage _tokenStorage;

  Future<User> _persistAndReturn(AuthPayloadModel payload) async {
    await _tokenStorage.saveTokens(
      accessToken: payload.accessToken,
      refreshToken: payload.refreshToken,
    );
    return payload.user;
  }

  @override
  Future<User> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final payload = await _dataSource.register(
      displayName: displayName,
      email: email,
      password: password,
    );
    return _persistAndReturn(payload);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final payload = await _dataSource.login(email: email, password: password);
    return _persistAndReturn(payload);
  }

  @override
  Future<User?> restoreSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final payload = await _dataSource.refresh(refreshToken);
      return _persistAndReturn(payload);
    } on ServerFailure catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _tokenStorage.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<User> updateDisplayName(String displayName) =>
      _dataSource.updateDisplayName(displayName);

  @override
  Future<void> logout() async {
    try {
      await _dataSource.logout();
    } on Failure {
      // On efface quand même les jetons locaux même si le serveur est injoignable.
    } finally {
      await _tokenStorage.clear();
    }
  }
}
