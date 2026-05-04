// ============================================================
// FILE: remote_auth_repository.dart
// PURPOSE: Implementación real de AuthRepository.
//
// FUENTES DE AUTH:
//   ✅ Email / Password — backend Node.js + JWT (BackendAuthService)
//   ✅ Google Sign-In   — Firebase Auth (popup web / google_sign_in móvil)
//   ✅ GitHub OAuth     — Firebase Auth (popup web / signInWithProvider móvil)
//
// El JWT del backend se persiste en TokenStorage (secure storage) y
// se inyecta automáticamente como Bearer en cada request via interceptor.
// Los flujos OAuth no usan TokenStorage: su sesión vive en Firebase.
// ============================================================

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisalle/core/auth/token_storage.dart';
import 'package:unisalle/core/config/auth_config.dart';
import 'package:unisalle/core/network/api_exceptions.dart';
import 'package:unisalle/features/auth/data/auth_repository.dart'
    show AuthCancelledException, AuthRepository;
import 'package:unisalle/features/auth/data/backend_auth_service.dart';
import 'package:unisalle/models/user.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required BackendAuthService backendAuth,
    required TokenStorage tokenStorage,
  })  : _backendAuth = backendAuth,
        _tokenStorage = tokenStorage,
        _googleSignIn = GoogleSignIn(scopes: GoogleAuthConfig.scopes);

  final BackendAuthService _backendAuth;
  final TokenStorage _tokenStorage;
  final GoogleSignIn _googleSignIn;

  // ── Email / Password (backend Node.js) ──────────────────────────────────

  @override
  Future<User> loginWithEmail(String email, String password) async {
    try {
      final session = await _backendAuth.login(email, password);
      await _tokenStorage.save(session.token);
      return session.user;
    } on DioException catch (e) {
      throw Exception(_mapBackendError(e));
    }
  }

  @override
  Future<User> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final session = await _backendAuth.register(name, email, password);
      await _tokenStorage.save(session.token);
      return session.user;
    } on DioException catch (e) {
      throw Exception(_mapBackendError(e));
    }
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null || token.isEmpty) return null;
    try {
      return await _backendAuth.me();
    } on DioException {
      // El interceptor ya limpió el token si fue 401. Cualquier otro
      // error de red deja la sesión en limbo: devolvemos null para que
      // el usuario haga login manualmente.
      return null;
    }
  }

  @override
  Future<User> updateProfileImage(String userId, File image) async {
    try {
      return await _backendAuth.updateProfileImage(userId, image);
    } on DioException catch (e) {
      throw Exception(_mapBackendError(e));
    }
  }

  // ── Google Sign-In (Firebase) ───────────────────────────────────────────

  @override
  Future<User> loginWithGoogle() async {
    try {
      fb.UserCredential credential;

      if (kIsWeb) {
        credential = await fb.FirebaseAuth.instance
            .signInWithPopup(fb.GoogleAuthProvider());
      } else {
        final account = await _googleSignIn.signIn();
        if (account == null) throw const AuthCancelledException();

        final auth = await account.authentication;
        final fbCredential = fb.GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        credential = await fb.FirebaseAuth.instance
            .signInWithCredential(fbCredential);
      }

      final fbUser = credential.user!;
      return User(
        id: fbUser.uid,
        name: fbUser.displayName ?? 'Usuario de Google',
        email: fbUser.email ?? '',
        photoUrl: fbUser.photoURL,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── GitHub OAuth (Firebase) ─────────────────────────────────────────────

  @override
  Future<User> loginWithGithub() async {
    try {
      final provider = fb.GithubAuthProvider()
        ..addScope('read:user')
        ..addScope('user:email');

      final fb.UserCredential credential;
      if (kIsWeb) {
        credential =
            await fb.FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        credential =
            await fb.FirebaseAuth.instance.signInWithProvider(provider);
      }

      final fbUser = credential.user!;
      return User(
        id: fbUser.uid,
        name: fbUser.displayName ?? 'GitHub User',
        email: fbUser.email ?? '',
        photoUrl: fbUser.photoURL,
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'web-context-cancelled' || e.code == 'cancelled') {
        throw const AuthCancelledException();
      }
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    // Limpia el JWT del backend (secure storage). Los flujos OAuth viven
    // en Firebase; cerrar sesión también allí.
    await _tokenStorage.clear();
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ── Mapeo de errores ────────────────────────────────────────────────────

  String _mapBackendError(DioException e) {
    final err = e.error;
    if (err is ValidationException) {
      if (err.errors.isNotEmpty) {
        return err.errors.map((v) => v.message).join('\n');
      }
      return err.message;
    }
    if (err is UnauthorizedException) {
      return 'Credenciales incorrectas.';
    }
    if (err is ApiException) {
      return err.message;
    }
    return 'No se pudo contactar al servidor. Verifica tu conexión.';
  }

  String _mapFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Intenta de nuevo.';
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'network-request-failed':
        return 'Sin conexión. Verifica tu red.';
      case 'popup-closed-by-user':
        return 'Login cancelado.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este email usando otro método de login.';
      case 'popup-blocked':
        return 'El popup fue bloqueado. Permite popups para este sitio.';
      case 'operation-not-allowed':
        return 'Este método de login no está habilitado.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }
}
