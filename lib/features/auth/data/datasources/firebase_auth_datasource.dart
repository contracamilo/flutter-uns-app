import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unisalle/core/config/auth_config.dart';
import 'package:unisalle/features/auth/data/models/user_model.dart';

/// Lanzada por el data source cuando el usuario cancela explícitamente
/// el flujo OAuth (popup cerrado, account picker descartado). El
/// repositorio la mapea a `CancelledFailure` para que no se muestre
/// como error en la UI.
class OAuthCancelled implements Exception {
  const OAuthCancelled();
}

/// Data source para los flujos OAuth de Firebase (Google y GitHub).
/// El token de Firebase no se persiste en `TokenStorage` — la sesión
/// vive en Firebase y se cierra con `signOut()`.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource({fb.FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: GoogleAuthConfig.scopes);

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Future<UserModel> signInWithGoogle() async {
    fb.UserCredential credential;

    if (kIsWeb) {
      credential = await _firebaseAuth.signInWithPopup(fb.GoogleAuthProvider());
    } else {
      final account = await _googleSignIn.signIn();
      if (account == null) throw const OAuthCancelled();

      final auth = await account.authentication;
      final fbCredential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      credential = await _firebaseAuth.signInWithCredential(fbCredential);
    }

    return _userFromCredential(credential, fallbackName: 'Usuario de Google');
  }

  Future<UserModel> signInWithGithub() async {
    final provider = fb.GithubAuthProvider()
      ..addScope('read:user')
      ..addScope('user:email');

    final fb.UserCredential credential;
    try {
      if (kIsWeb) {
        credential = await _firebaseAuth.signInWithPopup(provider);
      } else {
        credential = await _firebaseAuth.signInWithProvider(provider);
      }
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'web-context-cancelled' || e.code == 'cancelled') {
        throw const OAuthCancelled();
      }
      rethrow;
    }

    return _userFromCredential(credential, fallbackName: 'GitHub User');
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  UserModel _userFromCredential(
    fb.UserCredential credential, {
    required String fallbackName,
  }) {
    final fbUser = credential.user!;
    return UserModel(
      id: fbUser.uid,
      name: fbUser.displayName ?? fallbackName,
      email: fbUser.email ?? '',
      photoUrl: fbUser.photoURL,
    );
  }
}
