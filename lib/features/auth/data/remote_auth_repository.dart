// ============================================================
// FILE: remote_auth_repository.dart
// PURPOSE: Implementación real de AuthRepository usando Firebase Auth.
//
// ESTADO DE IMPLEMENTACIÓN:
//   ✅ Email / Password — Firebase Authentication
//   ✅ Google Sign-In   — firebase_auth popup (web) / google_sign_in (móvil)
//   ✅ GitHub OAuth     — firebase_auth popup (web) / signInWithProvider (móvil)
//                         Firebase guarda el client_secret; el cliente nunca lo ve.
// ============================================================

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisalle/core/config/auth_config.dart';
import 'package:unisalle/features/auth/data/auth_repository.dart'
    show AuthCancelledException, AuthRepository;
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
        email: fbUser.email!,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── GitHub OAuth 2.0 via Firebase Auth ───────────────────────────────────
  //
  // Firebase guarda el client_secret de GitHub en su servidor.
  // El cliente solo solicita el proveedor; Firebase maneja el intercambio
  // code → access_token internamente.
  //
  // PREREQUISITOS (una vez):
  //   1. GitHub OAuth App → Authorization callback URL:
  //      https://soa-arch-soft.firebaseapp.com/__/auth/handler
  //   2. Firebase Console → Authentication → GitHub → habilitar con
  //      Client ID y Client Secret de la GitHub OAuth App.

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
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'web-context-cancelled' || e.code == 'cancelled') {
        throw const AuthCancelledException();
      }
      throw Exception(_mapFirebaseError(e));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    await fb.FirebaseAuth.instance.signOut();
    // signOut del SDK de Google es opcional (limpia el estado local para que
    // el selector de cuentas aparezca en el próximo login). Se ignoran errores
    // porque puede fallar si el usuario no inició sesión con Google.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
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
