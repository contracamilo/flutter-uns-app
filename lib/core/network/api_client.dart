import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/auth/token_storage.dart';
import 'package:unisalle/core/config/api_config.dart';
import 'package:unisalle/core/network/api_exceptions.dart';

/// Construye un `Dio` apuntando al backend y registra el interceptor
/// que inyecta `Authorization: Bearer <token>` y traduce errores HTTP
/// a las excepciones tipadas en [api_exceptions.dart].
Dio buildApiClient(TokenStorage tokenStorage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}',
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      contentType: 'application/json',
      responseType: ResponseType.json,
      // No lanzar por status codes 4xx/5xx — el interceptor de errores
      // los convierte en ApiException tipadas más abajo.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(_AuthInterceptor(tokenStorage));
  dio.interceptors.add(_ErrorInterceptor(tokenStorage));

  return dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage);
  final TokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor(this._storage);
  final TokenStorage _storage;

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      handler.next(response);
      return;
    }

    final data = response.data;
    final message = _extractMessage(data) ?? 'Error inesperado del servidor.';

    if (status == 401 || status == 403) {
      await _storage.clear();
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: UnauthorizedException(message),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (status == 400 || status == 422) {
      final errors = _extractValidationErrors(data);
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: ValidationException(message, errors: errors, code: status),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: ApiException(message, statusCode: status),
        type: DioExceptionType.badResponse,
      ),
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Si ya empaquetamos una excepción tipada en onResponse, deja pasar.
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    final wrapped = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: ApiException(
        _readableNetworkError(err),
        statusCode: err.response?.statusCode,
      ),
    );
    handler.next(wrapped);
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final raw = data['message'] ?? data['error'];
      if (raw is String && raw.isNotEmpty) return raw;
    }
    return null;
  }

  List<ValidationError> _extractValidationErrors(dynamic data) {
    if (data is Map<String, dynamic> && data['errors'] is List) {
      return (data['errors'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ValidationError.fromJson)
          .toList(growable: false);
    }
    return const [];
  }

  String _readableNetworkError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Verifica tu conexión.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servidor. ¿Está corriendo el backend?';
      case DioExceptionType.cancel:
        return 'Operación cancelada.';
      default:
        return err.message ?? 'Error de red desconocido.';
    }
  }
}

/// Provider público del cliente HTTP. Construido una sola vez por sesión.
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return buildApiClient(storage);
});
