import 'package:equatable/equatable.dart';

/// Falla devuelta por los UseCases de auth dentro de un `Either`.
///
/// Las fallas viajan como **valores**, no como excepciones, para mantener
/// la separación entre capas: el BLoC puede mapearlas a estados sin
/// conocer la implementación concreta del repositorio o data source.
sealed class AuthFailure extends Equatable {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Credenciales incorrectas (email o contraseña inválidos).
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Credenciales incorrectas.',
  ]);
}

/// Errores de validación devueltos por el backend (HTTP 400/422).
/// Incluye el mapa `field → message` para mostrar errores por campo.
class ValidationFailure extends AuthFailure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Falla de red (timeout, sin conexión, host inalcanzable).
class NetworkFailure extends AuthFailure {
  const NetworkFailure([
    super.message =
        'No se pudo contactar al servidor. Verifica tu conexión.',
  ]);
}

/// Sesión expirada o token inválido (HTTP 401/403).
class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure([
    super.message = 'Sesión inválida o expirada.',
  ]);
}

/// El usuario canceló voluntariamente un flujo OAuth (popup cerrado,
/// rechazo en la pantalla del proveedor). No debe mostrarse como error.
class CancelledFailure extends AuthFailure {
  const CancelledFailure() : super('Operación cancelada por el usuario.');
}

/// Cualquier otro fallo no clasificado (incluye errores del proveedor
/// OAuth como `email-already-in-use`, `weak-password`, etc).
class UnexpectedFailure extends AuthFailure {
  const UnexpectedFailure([
    super.message = 'Ocurrió un error inesperado. Intenta de nuevo.',
  ]);
}
