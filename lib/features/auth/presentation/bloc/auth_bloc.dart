import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/domain/failures/auth_failure.dart';
import 'package:unisalle/features/auth/domain/usecases/login_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/login_with_github_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/logout_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/register_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/update_profile_image_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC de autenticación.
///
/// Recibe los UseCases por constructor (Inyección de Dependencias) y
/// delega cualquier lógica de datos en ellos. La validación reactiva
/// del formulario también vive aquí: cada `*Changed` recalcula los
/// errores y el botón de submit se habilita solo si `isLoginValid` /
/// `isRegisterValid`.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required LoginWithGithubUseCase loginWithGithubUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required UpdateProfileImageUseCase updateProfileImageUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _loginWithGithubUseCase = loginWithGithubUseCase,
        _logoutUseCase = logoutUseCase,
        _restoreSessionUseCase = restoreSessionUseCase,
        _updateProfileImageUseCase = updateProfileImageUseCase,
        super(const AuthState(status: AuthStatus.restoring)) {
    on<AuthSessionRestoreRequested>(_onRestoreSession);

    on<AuthLoginEmailChanged>(_onLoginEmailChanged);
    on<AuthLoginPasswordChanged>(_onLoginPasswordChanged);
    on<AuthLoginSubmitted>(_onLoginSubmitted);

    on<AuthRegisterNameChanged>(_onRegisterNameChanged);
    on<AuthRegisterEmailChanged>(_onRegisterEmailChanged);
    on<AuthRegisterPasswordChanged>(_onRegisterPasswordChanged);
    on<AuthRegisterConfirmPasswordChanged>(_onRegisterConfirmPasswordChanged);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);

    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthGithubSignInRequested>(_onGithubSignIn);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileImageUpdateRequested>(_onUpdateProfileImage);
    on<AuthFormReset>(_onFormReset);
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final LoginWithGithubUseCase _loginWithGithubUseCase;
  final LogoutUseCase _logoutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;
  final UpdateProfileImageUseCase _updateProfileImageUseCase;

  // ── Restaurar sesión al arrancar ───────────────────────────────────────

  Future<void> _onRestoreSession(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.restoring));
    final result = await _restoreSessionUseCase();
    result.fold(
      (_) => emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      )),
      (user) => emit(state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
        clearUser: user == null,
      )),
    );
  }

  // ── Login form ─────────────────────────────────────────────────────────

  void _onLoginEmailChanged(
    AuthLoginEmailChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(email: EmailField.dirty(event.email), clearError: true));
  }

  void _onLoginPasswordChanged(
    AuthLoginPasswordChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      password: PasswordField.dirty(event.password),
      clearError: true,
    ));
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final email = EmailField.dirty(state.email.value);
    final password = PasswordField.dirty(state.password.value);
    if (!email.isValid || !password.isValid) {
      emit(state.copyWith(email: email, password: password));
      return;
    }
    emit(state.copyWith(
      status: AuthStatus.loading,
      email: email,
      password: password,
      clearError: true,
    ));
    final result = await _loginUseCase(
      LoginParams(email: email.value, password: password.value),
    );
    _emitAuthResult(result, emit);
  }

  // ── Register form ──────────────────────────────────────────────────────

  void _onRegisterNameChanged(
    AuthRegisterNameChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      name: NameField.dirty(event.name),
      clearError: true,
    ));
  }

  void _onRegisterEmailChanged(
    AuthRegisterEmailChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      email: EmailField.dirty(event.email),
      clearError: true,
    ));
  }

  void _onRegisterPasswordChanged(
    AuthRegisterPasswordChanged event,
    Emitter<AuthState> emit,
  ) {
    final password = PasswordField.dirty(event.password);
    final confirm = ConfirmPasswordField.dirty(
      value: state.confirmPassword.value,
      password: password.value,
    );
    emit(state.copyWith(
      password: password,
      confirmPassword: confirm,
      clearError: true,
    ));
  }

  void _onRegisterConfirmPasswordChanged(
    AuthRegisterConfirmPasswordChanged event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      confirmPassword: ConfirmPasswordField.dirty(
        value: event.confirmPassword,
        password: state.password.value,
      ),
      clearError: true,
    ));
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final name = NameField.dirty(state.name.value);
    final email = EmailField.dirty(state.email.value);
    final password = PasswordField.dirty(state.password.value);
    final confirm = ConfirmPasswordField.dirty(
      value: state.confirmPassword.value,
      password: password.value,
    );
    if (!name.isValid ||
        !email.isValid ||
        !password.isValid ||
        !confirm.isValid) {
      emit(state.copyWith(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirm,
      ));
      return;
    }
    emit(state.copyWith(
      status: AuthStatus.loading,
      name: name,
      email: email,
      password: password,
      confirmPassword: confirm,
      clearError: true,
    ));
    final result = await _registerUseCase(
      RegisterParams(
        name: name.value.trim(),
        email: email.value.trim(),
        password: password.value,
      ),
    );
    _emitAuthResult(result, emit);
  }

  // ── OAuth ──────────────────────────────────────────────────────────────

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _loginWithGoogleUseCase();
    _emitAuthResult(result, emit);
  }

  Future<void> _onGithubSignIn(
    AuthGithubSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    final result = await _loginWithGithubUseCase();
    _emitAuthResult(result, emit);
  }

  // ── Logout ─────────────────────────────────────────────────────────────

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(const AuthState.initial());
  }

  // ── Profile image ──────────────────────────────────────────────────────

  Future<void> _onUpdateProfileImage(
    AuthProfileImageUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.user;
    if (current == null) return;
    final result = await _updateProfileImageUseCase(
      UpdateProfileImageParams(userId: current.id, image: event.image),
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (user) => emit(state.copyWith(user: user)),
    );
  }

  // ── Reset ──────────────────────────────────────────────────────────────

  void _onFormReset(AuthFormReset event, Emitter<AuthState> emit) {
    emit(AuthState(
      status: state.status,
      user: state.user,
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _emitAuthResult(
    dynamic result,
    Emitter<AuthState> emit,
  ) {
    // result es siempre Either<AuthFailure, User>
    result.fold(
      (failure) {
        if (failure is CancelledFailure) {
          // Cancelación voluntaria: volvemos al estado anterior sin error.
          emit(state.copyWith(
            status: state.user == null
                ? AuthStatus.unauthenticated
                : AuthStatus.authenticated,
            clearError: true,
          ));
          return;
        }
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: (failure as AuthFailure).message,
        ));
      },
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user as User,
        clearError: true,
      )),
    );
  }
}
