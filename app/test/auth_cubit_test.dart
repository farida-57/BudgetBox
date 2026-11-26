import 'package:bloc_test/bloc_test.dart';
import 'package:budgetbox/core/error/failure.dart';
import 'package:budgetbox/features/auth/domain/entities/user.dart';
import 'package:budgetbox/features/auth/domain/usecases/login_usecase.dart';
import 'package:budgetbox/features/auth/domain/usecases/logout_usecase.dart';
import 'package:budgetbox/features/auth/domain/usecases/register_usecase.dart';
import 'package:budgetbox/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:budgetbox/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:budgetbox/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:budgetbox/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockRestoreSessionUseCase extends Mock implements RestoreSessionUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

const _user = User(id: 'u1', displayName: 'Awa', email: 'awa@test.com');

AuthCubit buildCubit({
  MockLoginUseCase? login,
  MockRegisterUseCase? register,
  MockLogoutUseCase? logout,
  MockRestoreSessionUseCase? restore,
  MockUpdateProfileUseCase? updateProfile,
}) {
  return AuthCubit(
    loginUseCase: login ?? MockLoginUseCase(),
    registerUseCase: register ?? MockRegisterUseCase(),
    logoutUseCase: logout ?? MockLogoutUseCase(),
    restoreSessionUseCase: restore ?? MockRestoreSessionUseCase(),
    updateProfileUseCase: updateProfile ?? MockUpdateProfileUseCase(),
  );
}

void main() {
  group('AuthCubit.checkSession', () {
    blocTest<AuthCubit, AuthState>(
      'émet AuthAuthenticated quand une session est restaurée',
      build: () {
        final restore = MockRestoreSessionUseCase();
        when(() => restore()).thenAnswer((_) async => _user);
        return buildCubit(restore: restore);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [const AuthUnknown(), const AuthAuthenticated(_user)],
    );

    blocTest<AuthCubit, AuthState>(
      'émet AuthUnauthenticated sans session',
      build: () {
        final restore = MockRestoreSessionUseCase();
        when(() => restore()).thenAnswer((_) async => null);
        return buildCubit(restore: restore);
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [const AuthUnknown(), const AuthUnauthenticated()],
    );
  });

  group('AuthCubit.login', () {
    test('retourne null et authentifie en cas de succès', () async {
      final login = MockLoginUseCase();
      when(() => login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => _user);
      final cubit = buildCubit(login: login);

      final result = await cubit.login(email: 'awa@test.com', password: 'mdp12345');

      expect(result, isNull);
      expect(cubit.state, const AuthAuthenticated(_user));
    });

    test('retourne le message d\'erreur en cas d\'échec', () async {
      final login = MockLoginUseCase();
      when(() => login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const ServerFailure('Identifiants invalides', statusCode: 401));
      final cubit = buildCubit(login: login);

      final result = await cubit.login(email: 'awa@test.com', password: 'mauvais');

      expect(result, 'Identifiants invalides');
      expect(cubit.state, isA<AuthUnknown>());
    });
  });

  group('AuthCubit.logout', () {
    blocTest<AuthCubit, AuthState>(
      'passe à AuthUnauthenticated après déconnexion',
      build: () {
        final login = MockLoginUseCase();
        final logout = MockLogoutUseCase();
        when(() => login(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => _user);
        when(() => logout()).thenAnswer((_) async {});
        final cubit = buildCubit(login: login, logout: logout);
        cubit.emit(const AuthAuthenticated(_user));
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [const AuthUnauthenticated()],
    );
  });
}
