// ============================================================
// FILE: auth_bloc_test.dart
// PURPOSE: Tests del AuthBloc con UseCases inyectados.
//
// COBERTURA:
//   - Validación reactiva de email / password
//   - login OK → AuthAuthenticated
//   - login fallido → AuthFailure con mensaje
//   - register OK
//   - logout vuelve a AuthInitial / unauthenticated
//   - restoreSession con / sin usuario
// ============================================================

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/usecases/login_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/login_with_github_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/logout_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/register_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/update_profile_image_usecase.dart';
import 'package:unisalle/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../helpers/fake_auth_repository.dart';

AuthBloc _buildBloc(FakeAuthRepository repo) => AuthBloc(
      loginUseCase: LoginUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      loginWithGoogleUseCase: LoginWithGoogleUseCase(repo),
      loginWithGithubUseCase: LoginWithGithubUseCase(repo),
      logoutUseCase: LogoutUseCase(repo),
      restoreSessionUseCase: RestoreSessionUseCase(repo),
      updateProfileImageUseCase: UpdateProfileImageUseCase(repo),
    );

void main() {
  group('AuthBloc', () {
    late FakeAuthRepository repo;
    late AuthBloc bloc;

    setUp(() {
      repo = FakeAuthRepository();
      bloc = _buildBloc(repo);
    });

    tearDown(() => bloc.close());

    test('estado inicial es restoring', () {
      expect(bloc.state.status, AuthStatus.restoring);
      expect(bloc.state.user, isNull);
    });

    // ── Validación reactiva ──────────────────────────────────────────────

    test('email vacío → email field inválido', () async {
      bloc.add(const AuthLoginEmailChanged(''));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.email.isValid, isFalse);
      expect(bloc.state.email.displayError, 'Ingresa un email válido');
    });

    test('email con @ → válido', () async {
      bloc.add(const AuthLoginEmailChanged('ana@test.com'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.email.isValid, isTrue);
      expect(bloc.state.email.displayError, isNull);
    });

    test('password < 6 → inválido', () async {
      bloc.add(const AuthLoginPasswordChanged('123'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.password.isValid, isFalse);
      expect(bloc.state.password.displayError, 'Mínimo 6 caracteres');
    });

    // ── Submit con campos inválidos ───────────────────────────────────────

    test('AuthLoginSubmitted con campos vacíos no llama al UseCase', () async {
      bloc.add(const AuthLoginSubmitted());
      await Future<void>.delayed(Duration.zero);
      expect(repo.loginCallCount, 0);
      expect(bloc.state.status, isNot(AuthStatus.loading));
    });

    // ── Login flow ────────────────────────────────────────────────────────

    test('login OK → AuthAuthenticated con user', () async {
      bloc.add(const AuthLoginEmailChanged('ana@test.com'));
      bloc.add(const AuthLoginPasswordChanged('secret123'));
      bloc.add(const AuthLoginSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.loginCallCount, 1);
      expect(repo.lastLoginEmail, 'ana@test.com');
      expect(repo.lastLoginPassword, 'secret123');
      expect(bloc.state.status, AuthStatus.authenticated);
      expect(bloc.state.user, isNotNull);
      expect(bloc.state.user!.email, 'ana@test.com');
    });

    test('login con InvalidCredentialsFailure → status=failure + mensaje',
        () async {
      repo.loginFailure = const InvalidCredentialsFailure();

      bloc.add(const AuthLoginEmailChanged('ana@test.com'));
      bloc.add(const AuthLoginPasswordChanged('secret123'));
      bloc.add(const AuthLoginSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, AuthStatus.failure);
      expect(bloc.state.errorMessage, contains('Credenciales'));
      expect(bloc.state.user, isNull);
    });

    // ── Register flow ─────────────────────────────────────────────────────

    test('register OK → AuthAuthenticated', () async {
      bloc.add(const AuthRegisterNameChanged('Ana'));
      bloc.add(const AuthRegisterEmailChanged('ana@test.com'));
      bloc.add(const AuthRegisterPasswordChanged('secret123'));
      bloc.add(const AuthRegisterConfirmPasswordChanged('secret123'));
      bloc.add(const AuthRegisterSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.registerCallCount, 1);
      expect(repo.lastRegisterName, 'Ana');
      expect(bloc.state.status, AuthStatus.authenticated);
    });

    test('register con confirm distinto → no envía request', () async {
      bloc.add(const AuthRegisterNameChanged('Ana'));
      bloc.add(const AuthRegisterEmailChanged('ana@test.com'));
      bloc.add(const AuthRegisterPasswordChanged('secret123'));
      bloc.add(const AuthRegisterConfirmPasswordChanged('different'));
      bloc.add(const AuthRegisterSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.registerCallCount, 0);
      expect(
        bloc.state.confirmPassword.displayError,
        'Las contraseñas no coinciden',
      );
    });

    // ── OAuth ─────────────────────────────────────────────────────────────

    test('Google sign-in OK → autenticado', () async {
      bloc.add(const AuthGoogleSignInRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, AuthStatus.authenticated);
      expect(bloc.state.user!.email, 'google@test.com');
    });

    test('GitHub sign-in OK → autenticado', () async {
      bloc.add(const AuthGithubSignInRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, AuthStatus.authenticated);
      expect(bloc.state.user!.email, 'github@test.com');
    });

    // ── Logout ────────────────────────────────────────────────────────────

    test('logout → AuthInitial (unauthenticated, user=null)', () async {
      bloc.add(const AuthLoginEmailChanged('ana@test.com'));
      bloc.add(const AuthLoginPasswordChanged('secret123'));
      bloc.add(const AuthLoginSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isAuthenticated, isTrue);

      bloc.add(const AuthLogoutRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.isAuthenticated, isFalse);
      expect(bloc.state.user, isNull);
      expect(repo.logoutCallCount, 1);
    });

    // ── restoreSession ────────────────────────────────────────────────────

    test('restoreSession sin token → unauthenticated', () async {
      bloc.add(const AuthSessionRestoreRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, AuthStatus.unauthenticated);
      expect(bloc.state.user, isNull);
    });

    test('restoreSession con usuario → authenticated', () async {
      const restored = User(id: 'u9', name: 'Restored', email: 'r@test.com');
      repo.restoreSessionResult = restored;

      bloc.add(const AuthSessionRestoreRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.status, AuthStatus.authenticated);
      expect(bloc.state.user, restored);
      expect(repo.restoreSessionCallCount, 1);
    });
  });

  group('AuthRepository contract via Either', () {
    test('login devuelve Right<User> en éxito', () async {
      final repo = FakeAuthRepository();
      final result = await LoginUseCase(repo)(
        const LoginParams(email: 'ana@test.com', password: 'secret123'),
      );
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (user) {
        expect(user.email, 'ana@test.com');
      });
    });

    test('login devuelve Left<AuthFailure> en error', () async {
      final repo = FakeAuthRepository()
        ..loginFailure = const InvalidCredentialsFailure();
      final result = await LoginUseCase(repo)(
        const LoginParams(email: 'x@test.com', password: 'wrong123'),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('logout devuelve Right<unit>', () async {
      final repo = FakeAuthRepository();
      final result = await LogoutUseCase(repo)();
      expect(result, equals(const Right<AuthFailure, Unit>(unit)));
    });
  });
}
