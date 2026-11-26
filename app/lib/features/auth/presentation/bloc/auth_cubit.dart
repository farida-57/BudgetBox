import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'auth_state.dart';

/// Gère la session : restauration, connexion, inscription, profil, déconnexion.
///
/// Les méthodes [login]/[register] retournent `null` en cas de succès
/// ou un message d'erreur lisible pour l'UI.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  })  : _login = loginUseCase,
        _register = registerUseCase,
        _logout = logoutUseCase,
        _restoreSession = restoreSessionUseCase,
        _updateProfile = updateProfileUseCase,
        super(const AuthUnknown());

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final RestoreSessionUseCase _restoreSession;
  final UpdateProfileUseCase _updateProfile;

  /// Appelé au démarrage : restaure la session via le refresh token.
  Future<void> checkSession() async {
    emit(const AuthUnknown());
    try {
      final user = await _restoreSession();
      emit(user == null ? const AuthUnauthenticated() : AuthAuthenticated(user));
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Retourne null si la connexion réussit, sinon le message d'erreur.
  Future<String?> login({required String email, required String password}) async {
    try {
      final user = await _login(email: email, password: password);
      emit(AuthAuthenticated(user));
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  /// Retourne null si l'inscription réussit, sinon le message d'erreur.
  Future<String?> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _register(displayName: displayName, email: email, password: password);
      emit(AuthAuthenticated(user));
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  /// Met à jour le nom d'affichage. Retourne null ou un message d'erreur.
  Future<String?> updateDisplayName(String displayName) async {
    final current = state;
    if (current is! AuthAuthenticated) return 'Session invalide';
    try {
      final user = await _updateProfile(displayName);
      emit(AuthAuthenticated(user));
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<void> logout() async {
    await _logout();
    emit(const AuthUnauthenticated());
  }

  static String _errorMessage(Object e) => e.toString();
}
