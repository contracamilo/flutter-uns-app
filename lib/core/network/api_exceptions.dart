/// Excepción base para errores HTTP/red al hablar con el backend.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Lanzada cuando el backend responde 401. La capa de red ya limpió
/// el token; los handlers superiores deben redirigir a login.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String? message])
      : super(message ?? 'Sesión inválida o expirada.', statusCode: 401);
}

/// Lanzada cuando express-validator devuelve `errors: [{field, message}]`
/// (status 400/422). Permite a la UI mostrar errores por campo.
class ValidationException extends ApiException {
  const ValidationException(super.message, {required this.errors, int? code})
      : super(statusCode: code ?? 400);

  final List<ValidationError> errors;
}

class ValidationError {
  const ValidationError({required this.field, required this.message});

  final String field;
  final String message;

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    final field =
        (json['path'] ?? json['field'] ?? json['param'] ?? '').toString();
    final message =
        (json['msg'] ?? json['message'] ?? 'Valor inválido').toString();
    return ValidationError(field: field, message: message);
  }

  @override
  String toString() => '$field: $message';
}
