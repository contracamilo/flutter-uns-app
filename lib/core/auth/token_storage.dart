import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper sobre `FlutterSecureStorage` para persistir el JWT del backend.
///
/// El token vive en Keychain (iOS) o EncryptedSharedPreferences (Android),
/// fuera del sandbox de la app y protegido por las APIs de seguridad del SO.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _kToken = 'auth_jwt_token';

  Future<String?> read() => _storage.read(key: _kToken);

  Future<void> save(String token) => _storage.write(key: _kToken, value: token);

  Future<void> clear() => _storage.delete(key: _kToken);
}

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
