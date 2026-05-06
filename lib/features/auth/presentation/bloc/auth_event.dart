part of 'auth_bloc.dart';

/// Eventos que el BLoC de autenticación procesa.
///
/// Se modelan como `sealed class` + `Equatable` para que cada evento
/// sea un valor inmutable comparable y para que el `switch` exhaustivo
/// del BLoC sea verificable en tiempo de compilación.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

// ── Validación reactiva del formulario de login ──────────────────────────

class AuthLoginEmailChanged extends AuthEvent {
  const AuthLoginEmailChanged(this.email);
  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthLoginPasswordChanged extends AuthEvent {
  const AuthLoginPasswordChanged(this.password);
  final String password;

  @override
  List<Object?> get props => [password];
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted();
}

// ── Validación reactiva del formulario de registro ───────────────────────

class AuthRegisterNameChanged extends AuthEvent {
  const AuthRegisterNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

class AuthRegisterEmailChanged extends AuthEvent {
  const AuthRegisterEmailChanged(this.email);
  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthRegisterPasswordChanged extends AuthEvent {
  const AuthRegisterPasswordChanged(this.password);
  final String password;

  @override
  List<Object?> get props => [password];
}

class AuthRegisterConfirmPasswordChanged extends AuthEvent {
  const AuthRegisterConfirmPasswordChanged(this.confirmPassword);
  final String confirmPassword;

  @override
  List<Object?> get props => [confirmPassword];
}

class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted();
}

// ── OAuth y sesión ────────────────────────────────────────────────────────

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthGithubSignInRequested extends AuthEvent {
  const AuthGithubSignInRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionRestoreRequested extends AuthEvent {
  const AuthSessionRestoreRequested();
}

class AuthProfileImageUpdateRequested extends AuthEvent {
  const AuthProfileImageUpdateRequested(this.image);
  final File image;

  @override
  List<Object?> get props => [image.path];
}

/// Permite a la UI reiniciar el formulario de login al volver a entrar
/// a la pantalla, conservando el usuario autenticado si lo hubiera.
class AuthFormReset extends AuthEvent {
  const AuthFormReset();
}
