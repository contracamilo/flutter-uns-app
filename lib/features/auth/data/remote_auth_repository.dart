// ============================================================
// FILE: remote_auth_repository.dart
// PURPOSE: Implementación real de AuthRepository usando OAuth 2.0.
//
// ESTADO DE IMPLEMENTACIÓN:
//   ✅ Google Sign-In   — SDK nativo, perfil obtenido del proveedor
//   ✅ GitHub OAuth     — Authorization Code Flow, code capturado
//   ⏳ Email/password   — Requiere backend propio
//   ⏳ Token exchange   — Google idToken y GitHub code pendientes de
//                         validación/intercambio en backend
//
// SEGURIDAD:
//   El `client_secret` de GitHub NUNCA viaja al cliente.
//   El intercambio code → access_token se hace desde el backend.
//   Ver docs/AUTH_SETUP.md §3 "Integración con backend".
// ============================================================

import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisalle/core/config/auth_config.dart';
import 'package:unisalle/features/auth/data/auth_repository.dart';
import 'package:unisalle/models/user.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository()
      : _googleSignIn = GoogleSignIn(scopes: GoogleAuthConfig.scopes);

  final GoogleSignIn _googleSignIn;

  // ── Email / Password ──────────────────────────────────────────────────────

  @override
  Future<User> loginWithEmail(String email, String password) async {
    try {
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final fbUser = credential.user!;
      return User(
        id: fbUser.uid,
        name: fbUser.displayName ?? email.split('@').first,
        email: fbUser.email!,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  @override
  Future<User> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(name);
      return User(id: credential.user!.uid, name: name, email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  //
  // FLUJO:
  //   1. [✅] SDK abre el selector de cuentas de Google nativo
  //   2. [✅] Obtener GoogleSignInAccount con perfil y tokens
  //   3. [⏳] Enviar idToken al backend para verificación y sesión
  //
  // PREREQUISITOS — ver docs/AUTH_SETUP.md §1:
  //   • Proyecto en Google Cloud Console con OAuth 2.0
  //   • GoogleService-Info.plist en ios/Runner/          (iOS)
  //   • google-services.json en android/app/             (Android)
  //   • SHA-1 del keystore de debug/release registrado   (Android)

  @override
  Future<User> loginWithGoogle() async {
    try {
      fb.UserCredential credential;

      if (kIsWeb) {
        // Web: Firebase abre el popup de Google directamente.
        // No necesita google_sign_in ni CLIENT_ID en el cliente.
        credential = await fb.FirebaseAuth.instance
            .signInWithPopup(fb.GoogleAuthProvider());
      } else {
        // iOS / Android: google_sign_in obtiene los tokens OAuth,
        // que luego se intercambian por una sesión Firebase.
        final account = await _googleSignIn.signIn();
        if (account == null) throw Exception('Login con Google cancelado.');

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
        email: fbUser.email!,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── GitHub OAuth 2.0 ─────────────────────────────────────────────────────
  //
  // FLUJO — Authorization Code Flow (RFC 6749 §4.1):
  //   1. [✅] Generar `state` aleatorio para protección CSRF
  //   2. [✅] Abrir browser in-app en github.com/login/oauth/authorize
  //   3. [✅] Capturar callback: unisalle://auth/callback?code=CODE&state=STATE
  //   4. [✅] Validar state (CSRF)
  //   5. [⏳] Backend intercambia code → access_token con GitHub
  //   6. [⏳] Backend llama GET /user en GitHub API y crea sesión
  //
  // POR QUÉ EL INTERCAMBIO VA EN EL BACKEND:
  //   GitHub exige `client_secret` para el intercambio. Si este secreto
  //   viviera en el APK/IPA, cualquier persona con acceso al binario
  //   podría extraerlo con herramientas de ingeniería inversa.
  //
  // PREREQUISITOS — ver docs/AUTH_SETUP.md §2:
  //   • GitHub OAuth App en github.com/settings/developers
  //   • Authorization callback URL: unisalle://auth/callback
  //   • GithubAuthConfig.clientId actualizado con el Client ID real

  String? _pendingGithubState;

  @override
  Future<User> loginWithGithub() async {
    // Paso 1 — Generar state CSRF de 128 bits (URL-safe Base64)
    final state = _generateSecureState();
    _pendingGithubState = state;

    // Paso 2 — Construir URL de autorización
    final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': GithubAuthConfig.clientId,
      'scope': GithubAuthConfig.scope,
      'state': state,
      'redirect_uri': GithubAuthConfig.redirectUri,
    });

    try {
      // Paso 3 — Abrir browser in-app y esperar callback.
      // flutter_web_auth_2 usa:
      //   iOS:     ASWebAuthenticationSession (sesión aislada, sin cookies de Safari)
      //   Android: Chrome Custom Tabs
      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: GithubAuthConfig.callbackScheme,
      );

      // Paso 4 — Validar state (protección CSRF)
      final callbackUri = Uri.parse(callbackUrl);
      final returnedState = callbackUri.queryParameters['state'];
      final code = callbackUri.queryParameters['code'];

      if (returnedState != _pendingGithubState) {
        throw Exception(
          'Estado de seguridad inválido — posible ataque CSRF.',
        );
      }
      _pendingGithubState = null;

      if (code == null) {
        throw Exception('GitHub no devolvió el código de autorización.');
      }

      // Paso 5 (TODO) — Enviar `code` al backend para intercambiarlo.
      // ⚠️ NUNCA hagas este intercambio desde el cliente.
      //
      //   final response = await http.post(
      //     Uri.parse('${ApiConfig.baseUrl}/auth/github/callback'),
      //     headers: {'Content-Type': 'application/json'},
      //     body: jsonEncode({'code': code}),
      //   );
      //   if (response.statusCode != 200) {
      //     throw Exception('Error al autenticar con GitHub');
      //   }
      //   final data = jsonDecode(response.body) as Map<String, dynamic>;
      //   await _saveSessionToken(data['session_token'] as String);

      // Paso 6 (TODO) — El backend usa el access_token para GET /user:
      //
      //   GET https://api.github.com/user
      //   Authorization: Bearer <access_token>
      //   Accept: application/vnd.github+json
      //
      //   Los emails privados están en:
      //   GET https://api.github.com/user/emails
      //
      //   return User.fromJson(data['user'] as Map<String, dynamic>);

      // Provisional: usuario temporal con el code validado.
      // El nombre/email real vendrá del backend en el paso 6.
      return User(
        id: 'github-${DateTime.now().millisecondsSinceEpoch}',
        name: 'GitHub User',
        email: 'pending@github.com',
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw Exception('Login con GitHub cancelado.');
      }
      rethrow;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    await fb.FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
        return 'Login con Google cancelado.';
      case 'operation-not-allowed':
        return 'Este método de login no está habilitado.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }

  /// Genera un state aleatorio criptográficamente seguro (128 bits).
  /// Codificado en Base64url para ser URL-safe sin padding.
  ///
  /// Propósito: prevenir ataques CSRF en el flujo OAuth.
  /// Ver: https://datatracker.ietf.org/doc/html/rfc6749#section-10.12
  String _generateSecureState() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
