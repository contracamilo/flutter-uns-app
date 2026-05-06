// ============================================================
// FILE: auth_providers.dart
// PURPOSE: Riverpod providers para la composición de auth.
//
// Riverpod aquí cumple el rol de **service locator**: registra
// data sources, repositorio y UseCases. La gestión de estado de
// la sesión y los formularios vive en `AuthBloc` (flutter_bloc),
// que se construye en `main.dart` leyendo estos providers vía
// `ProviderContainer`.
//
// El archivo legacy `auth_provider.dart` (singular) y el
// `AuthNotifier` AsyncNotifier fueron retirados al migrar a
// Clean Architecture + BLoC.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/auth/token_storage.dart';
import 'package:unisalle/core/network/api_client.dart';
import 'package:unisalle/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:unisalle/features/auth/data/datasources/backend_auth_datasource.dart';
import 'package:unisalle/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:unisalle/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';
import 'package:unisalle/features/auth/domain/usecases/login_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/login_with_github_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/logout_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/register_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:unisalle/features/auth/domain/usecases/update_profile_image_usecase.dart';
import 'package:unisalle/features/auth/presentation/bloc/auth_bloc.dart';

// ── Data sources ─────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BackendAuthDataSource(dio);
});

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

// ── Repositorio ──────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    firebaseDataSource: ref.watch(firebaseAuthDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

// ── UseCases ─────────────────────────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>(
  (ref) => LoginWithGoogleUseCase(ref.watch(authRepositoryProvider)),
);

final loginWithGithubUseCaseProvider = Provider<LoginWithGithubUseCase>(
  (ref) => LoginWithGithubUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>(
  (ref) => RestoreSessionUseCase(ref.watch(authRepositoryProvider)),
);

final updateProfileImageUseCaseProvider = Provider<UpdateProfileImageUseCase>(
  (ref) => UpdateProfileImageUseCase(ref.watch(authRepositoryProvider)),
);

// ── AuthBloc ─────────────────────────────────────────────────────────────
//
// El `AuthBloc` se registra como singleton en Riverpod para que tanto
// el `BlocProvider.value` del árbol de widgets como el `routerProvider`
// (auth guard) compartan la misma instancia. Riverpod se encarga de
// cerrarlo al disposear el `ProviderScope`.

final authBlocProvider = Provider<AuthBloc>((ref) {
  final bloc = AuthBloc(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    loginWithGoogleUseCase: ref.watch(loginWithGoogleUseCaseProvider),
    loginWithGithubUseCase: ref.watch(loginWithGithubUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    restoreSessionUseCase: ref.watch(restoreSessionUseCaseProvider),
    updateProfileImageUseCase: ref.watch(updateProfileImageUseCaseProvider),
  );
  bloc.add(const AuthSessionRestoreRequested());
  ref.onDispose(bloc.close);
  return bloc;
});
