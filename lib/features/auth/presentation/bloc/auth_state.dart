part of 'auth_bloc.dart';

/// Estado consumido por la UI de autenticación.
///
/// El estado mantiene a la vez el formulario reactivo y el estado del
/// usuario autenticado para que ambas pantallas (login/register) y los
/// guards de navegación puedan derivar lo que necesitan de un solo
/// `BlocBuilder`.
class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.email = const EmailField.pure(),
    this.password = const PasswordField.pure(),
    this.name = const NameField.pure(),
    this.confirmPassword = const ConfirmPasswordField.pure(),
    this.errorMessage,
  });

  const AuthState.initial() : this(status: AuthStatus.unauthenticated);

  /// Status global de la sesión + del request en curso.
  final AuthStatus status;

  /// Usuario autenticado, si lo hay. Null cuando `status` es
  /// `unauthenticated` o cuando aún no se restauró la sesión.
  final User? user;

  /// Campos del formulario, con su estado de validación.
  final EmailField email;
  final PasswordField password;
  final NameField name;
  final ConfirmPasswordField confirmPassword;

  /// Mensaje de error a mostrar (snackbar). El BLoC lo limpia al
  /// arrancar un nuevo intento.
  final String? errorMessage;

  bool get isLoginValid => email.isValid && password.isValid;

  bool get isRegisterValid =>
      name.isValid &&
      email.isValid &&
      password.isValid &&
      confirmPassword.isValid;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.restoring;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    EmailField? email,
    PasswordField? password,
    NameField? name,
    ConfirmPasswordField? confirmPassword,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        email,
        password,
        name,
        confirmPassword,
        errorMessage,
      ];
}

enum AuthStatus {
  /// Aún no sabemos si hay sesión persistida (al arrancar la app).
  restoring,

  /// No hay sesión activa.
  unauthenticated,

  /// Hay un request de auth en curso (login, register, OAuth, logout).
  loading,

  /// Sesión activa, `user` no es nulo.
  authenticated,

  /// El último intento falló. `errorMessage` describe el motivo.
  failure,
}

// ── Form fields ───────────────────────────────────────────────────────────
//
// Cada campo encapsula su valor + estado de validación. La UI usa
// `displayError` para decidir si mostrar el texto de error: un campo
// `pure` (sin tocar) nunca muestra error aunque sea inválido.

abstract class _FormField<T> extends Equatable {
  const _FormField({required this.value, required this.isPure});

  final T value;
  final bool isPure;

  String? get error;

  bool get isValid => error == null;

  /// `null` si todavía no se debe mostrar el error (campo no tocado).
  String? get displayError => isPure ? null : error;

  @override
  List<Object?> get props => [value, isPure];
}

class EmailField extends _FormField<String> {
  const EmailField.pure([String value = ''])
      : super(value: value, isPure: true);

  const EmailField.dirty([String value = ''])
      : super(value: value, isPure: false);

  @override
  String? get error {
    if (value.isEmpty || !value.contains('@')) {
      return 'Ingresa un email válido';
    }
    return null;
  }
}

class PasswordField extends _FormField<String> {
  const PasswordField.pure([String value = ''])
      : super(value: value, isPure: true);

  const PasswordField.dirty([String value = ''])
      : super(value: value, isPure: false);

  @override
  String? get error {
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}

class NameField extends _FormField<String> {
  const NameField.pure([String value = '']) : super(value: value, isPure: true);

  const NameField.dirty([String value = ''])
      : super(value: value, isPure: false);

  @override
  String? get error {
    if (value.trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }
}

class ConfirmPasswordField extends _FormField<String> {
  const ConfirmPasswordField.pure({super.value = '', this.password = ''})
      : super(isPure: true);

  const ConfirmPasswordField.dirty({super.value = '', this.password = ''})
      : super(isPure: false);

  final String password;

  @override
  String? get error {
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  @override
  List<Object?> get props => [value, isPure, password];
}
