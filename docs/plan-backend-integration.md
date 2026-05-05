# Plan — Integración backend Node.js como auth email/password de la app Flutter UniSalle

## Contexto

El estudiante tiene dos repos en `/Users/home/universidad/unisalle_backend/`:

- `unisalle_backend/` — backend Node.js + Express + Sequelize + MySQL (rama `main`).
- `unisalle/` — app Flutter con Riverpod (rama `feat/initial-boilerplate`, repo `contracamilo/flutter-uns-app` ya clonado).

La actividad académica pide demostrar un backend con MySQL, registro/login, JWT, roles many-to-many, /me, y actualización de usuario con imagen.

**Estado actual** (verificado leyendo archivos):

- **Backend**: ya está feature-complete. Tiene endpoints `/api/auth/register`, `/api/auth/login`, `/api/users/me`, `/api/users/:id`, `/api/users/:id/image`, `/api/health`. JWT firmado con `JWT_SECRET`, bcryptjs, express-validator, multer (5 MB, jpeg/png/webp/gif), modelos `User` ↔ `Role` con join `user_roles`, seed automático de roles `admin/user/moderator`, CORS abierto, bind `0.0.0.0:3000`, Docker Compose con MySQL 8 + healthcheck. README completo. **Nada falta para cumplir el rúbrica**.
- **Flutter**: usa `RemoteAuthRepository` con FirebaseAuth para *todo* (email/password, Google, GitHub). El `AuthRepository` es una abstracción limpia, así que el cambio es localizado. No hay cliente HTTP, ni storage seguro, ni base URL configurada. El modelo `User` solo tiene `id/name/email` — falta `photoUrl` y `roles`.

**Objetivo**: en la app Flutter, sustituir email/password de Firebase por llamadas al backend Node.js (con persistencia de JWT, refresco de sesión vía `/me`, y soporte para subir imagen de perfil), **manteniendo intactos** los flujos OAuth de Google y GitHub que siguen sobre Firebase. Trabajar cada repo en un worktree dedicado para poder iterar en paralelo sin contaminar `main`.

---

## Worktrees

Crear bajo `/Users/home/universidad/unisalle_backend/` (un nivel arriba de cada repo):

| Worktree | Repo | Rama nueva | Propósito |
|----------|------|------------|-----------|
| `unisalle-wt-auth/` | Flutter | `feat/backend-auth` (desde `feat/initial-boilerplate`) | Cambios cliente: Dio, secure storage, swap email/password |
| `unisalle_backend-wt-polish/` | Backend | `feat/auth-polish` (desde `main`) | Hardening opcional: helmet, rate-limit en `/api/auth`, README hint para Flutter |

Comandos (ejecutar al salir de plan mode):

```bash
cd /Users/home/universidad/unisalle_backend/unisalle && \
  git worktree add ../unisalle-wt-auth -b feat/backend-auth feat/initial-boilerplate

cd /Users/home/universidad/unisalle_backend/unisalle_backend && \
  git worktree add ../unisalle_backend-wt-polish -b feat/auth-polish main
```

> Nota: ya existen dos worktrees de Cursor en `~/.cursor/worktrees/unisalle/` — no tocarlos.

---

## Cambios — Flutter (`unisalle-wt-auth/`)

### 1. Dependencias (`pubspec.yaml`)

Añadir:

```yaml
dependencies:
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
  image_picker: ^1.1.2   # para el flujo de upload de imagen de perfil
```

### 2. Configuración de red

**Crear** [unisalle/lib/core/config/api_config.dart](unisalle/lib/core/config/api_config.dart):

- `String get apiBaseUrl` lee `String.fromEnvironment('API_BASE_URL')` con default por plataforma:
  - Android emulator → `http://10.0.2.2:3000`
  - iOS simulator / web / desktop → `http://localhost:3000`
- Documentar override por LAN para dispositivo físico vía `--dart-define=API_BASE_URL=http://192.168.x.x:3000`.

**Actualizar** `env/dev.json` (y `env/README.md`) con la nueva clave `API_BASE_URL`.

### 3. Cliente HTTP + interceptor JWT

**Crear** [unisalle/lib/core/network/api_client.dart](unisalle/lib/core/network/api_client.dart):

- `Provider<Dio>` con `BaseOptions(baseUrl, connectTimeout: 10s, receiveTimeout: 15s)`.
- `Interceptor` que:
  - En `onRequest`: añade `Authorization: Bearer <token>` si existe en `TokenStorage`.
  - En `onError`: si `401`, limpia el token y propaga.
- Mapeo de errores de red a excepciones tipadas (`ApiException`, `UnauthorizedException`, `ValidationException` con `errors: List<{field, message}>`).

### 4. Almacenamiento del JWT

**Crear** [unisalle/lib/core/auth/token_storage.dart](unisalle/lib/core/auth/token_storage.dart):

- Wrapper sobre `FlutterSecureStorage` con `saveToken`, `getToken`, `clearToken`.
- Provider `tokenStorageProvider`.
- En iOS usar `accessibility: first_unlock`; en Android, `EncryptedSharedPreferences`.

### 5. Servicio backend

**Crear** [unisalle/lib/features/auth/data/backend_auth_service.dart](unisalle/lib/features/auth/data/backend_auth_service.dart):

- `Future<({User user, String token})> login(String email, String password)` → `POST /api/auth/login`
- `Future<({User user, String token})> register(String name, String email, String password)` → `POST /api/auth/register`
- `Future<User> me()` → `GET /api/users/me` (usado para restaurar sesión)
- `Future<User> updateProfileImage(String userId, File image)` → `PUT /api/users/:id/image` (multipart)
- Mapeo del payload backend al modelo `User` local.

### 6. Modelo User extendido

**Modificar** [unisalle/lib/models/user.dart](unisalle/lib/models/user.dart):

- Añadir `final String? photoUrl;` y `final List<String> roles;` (default `const []`).
- Actualizar `copyWith`, `==`, `hashCode`, `fromJson`, `toJson` — siguiendo la plantilla de `CLAUDE.md`.
- `fromJson` debe tolerar la respuesta del backend: campo `image` → `photoUrl`, `roles` viene como `List<String>`.

### 7. Repositorio híbrido

**Modificar** [unisalle/lib/features/auth/data/remote_auth_repository.dart](unisalle/lib/features/auth/data/remote_auth_repository.dart):

- Inyectar `BackendAuthService` y `TokenStorage` por constructor.
- `loginWithEmail` y `registerWithEmail` (líneas 28–58): reemplazar las llamadas Firebase por `BackendAuthService` + `TokenStorage.saveToken`.
- Mantener `loginWithGoogle` (líneas 73–107) y `loginWithGithub` (líneas 121–149) **sin cambios**, salvo: tras el login Firebase, no se guarda token en `TokenStorage` (ese flujo no tiene JWT del backend).
- `logout` (líneas 153–162): añadir `tokenStorage.clearToken()` antes del `signOut` de Firebase.
- Mapeo de errores: traducir `ValidationException` a mensajes ES (similar a `_mapFirebaseError`).

**Actualizar** [unisalle/lib/features/auth/data/auth_repository.dart](unisalle/lib/features/auth/data/auth_repository.dart):

- Añadir método opcional `Future<User?> restoreSession()` que devuelve el usuario si hay JWT válido, `null` en caso contrario. `MockAuthRepository` devuelve `null`; `RemoteAuthRepository` llama a `BackendAuthService.me()` y si lanza 401, limpia token y devuelve `null`.

### 8. Provider de auth — restaurar sesión

**Modificar** [unisalle/lib/features/auth/providers/auth_provider.dart](unisalle/lib/features/auth/providers/auth_provider.dart):

- En `build()` (donde está el TODO líneas 46–48): llamar a `repository.restoreSession()` en lugar de devolver `null` directamente. Esto hace que el JWT persista entre reinicios.
- Inyectar dependencias del repo vía providers (refactor de `authRepositoryProvider` para construir `RemoteAuthRepository` con `Dio`, `BackendAuthService`, `TokenStorage`).

### 9. UI de perfil con upload de imagen (cumple rúbrica)

**Crear** `lib/features/profile/presentation/screens/profile_screen.dart` (o ampliar la pantalla actual si existe):

- Mostrar `user.name`, `user.email`, lista de `user.roles`, avatar desde `user.photoUrl` (vía `AppImage`).
- Botón "Cambiar foto" → `image_picker` → `BackendAuthService.updateProfileImage` → refresca `authProvider`.
- Solo visible cuando el login fue por backend (i.e., `tokenStorageProvider` tiene token). Para usuarios OAuth Firebase, mostrar mensaje "Cambia tu foto desde tu cuenta de Google/GitHub".

### 10. Tests

- `test/features/auth/backend_auth_service_test.dart` — mocks de Dio (`http_mock_adapter` o `MockAdapter`) cubriendo: login OK, login 401, register 422 con `errors[]`, `me()` 401, upload imagen 200.
- `test/features/auth/auth_provider_test.dart` — `restoreSession()` con `TokenStorage` fake.

### 11. Documentar

- Añadir sección "Backend de email/password" al README de Flutter con: cómo levantar el backend, variables `--dart-define`, troubleshooting (CORS, IP en LAN, certificados HTTP en Android > 9 con `usesCleartextTraffic` o `network_security_config.xml`).

---

## Cambios — Backend (`unisalle_backend-wt-polish/`)

El backend está completo. Solo hardening opcional + DX:

### 1. Seguridad (recomendado, no bloqueante)

- Añadir `helmet` en `src/config/server.js` para cabeceras HTTP defensivas.
- Añadir `express-rate-limit` solo sobre `/api/auth/*` (5 intentos / 15 min por IP) — mitiga fuerza bruta.
- Verificar que `bcryptjs` use `saltRounds >= 10`.
- Confirmar que `.env` no se commitea (`.gitignore` ya excluye `.env`, OK).
- Rotar `JWT_SECRET` del `.env` actual (`cambia_este_secreto_por_uno_seguro`) por uno generado con `openssl rand -base64 64` antes del demo.

### 2. CORS — endurecer para no-academia

- Hoy `origin: '*'`. Para dev local con la app móvil está bien. Documentar en README que en producción debe restringirse a dominios conocidos.

### 3. README

- Añadir sección "Integración con app Flutter UniSalle": IP base por plataforma, ejemplo de `curl` y JSON de respuesta de `/me`, nota sobre `Authorization: Bearer`.

### 4. Lo que NO se va a tocar

- `sequelize.sync({ alter: true })` — funciona para academia. Migraciones formales (sequelize-cli) son fuera de alcance.
- Refresh tokens — fuera de alcance (JWT 7 días es suficiente para el demo).
- Endpoint para que usuarios OAuth Firebase se mirroreen en MySQL — fuera de alcance (asimetría aceptada: roles solo aplican a usuarios email/password).

---

## Archivos críticos a modificar

**Flutter (worktree `unisalle-wt-auth/`):**

- [unisalle/pubspec.yaml](unisalle/pubspec.yaml) — deps
- [unisalle/lib/models/user.dart](unisalle/lib/models/user.dart) — extender
- [unisalle/lib/features/auth/data/auth_repository.dart](unisalle/lib/features/auth/data/auth_repository.dart) — añadir `restoreSession`
- [unisalle/lib/features/auth/data/remote_auth_repository.dart](unisalle/lib/features/auth/data/remote_auth_repository.dart) — swap email/pass
- [unisalle/lib/features/auth/providers/auth_provider.dart](unisalle/lib/features/auth/providers/auth_provider.dart) — restore + DI
- **Nuevos**: `lib/core/config/api_config.dart`, `lib/core/network/api_client.dart`, `lib/core/auth/token_storage.dart`, `lib/features/auth/data/backend_auth_service.dart`, `lib/features/profile/...`

**Backend (worktree `unisalle_backend-wt-polish/`):**

- [unisalle_backend/src/config/server.js](unisalle_backend/src/config/server.js) — helmet
- [unisalle_backend/src/routes/auth.routes.js](unisalle_backend/src/routes/auth.routes.js) — rate-limit
- [unisalle_backend/.env](unisalle_backend/.env) — rotar `JWT_SECRET`
- [unisalle_backend/README.md](unisalle_backend/README.md) — sección Flutter

---

## Verificación end-to-end (guion para el video)

1. **Backend arriba**:
   ```bash
   cd unisalle_backend && docker-compose up -d
   curl -s http://localhost:3000/api/health   # → {"status":"ok"}
   ```
2. **DB OK**: `docker exec -it <mysql_container> mysql -uroot -p -e "SHOW TABLES IN unisalle_db;"` → muestra `users`, `roles`, `user_roles`.
3. **Postman — registro**: `POST /api/auth/register` con `{name, email, password}` → 201 con `token` y `user.roles=["user"]`.
4. **Postman — login**: `POST /api/auth/login` → 200 con `token`.
5. **Postman — /me con Bearer**: `GET /api/users/me` → 200 con `user` + `roles`.
6. **Flutter — login email/password**: ejecuta app, registra desde la pantalla, navega a catálogo. Reinicia la app → sesión persiste (JWT en secure storage).
7. **Flutter — perfil + imagen**: pantalla perfil, "Cambiar foto", selecciona, upload → avatar muestra URL completa `http://<host>:3000/uploads/<uuid>.jpg`.
8. **Flutter — Google/GitHub**: confirma que ambos siguen funcionando (Firebase intacto).
9. **Logout**: token se borra de secure storage, usuario vuelve a `/welcome`.
10. **Tests**: `flutter test` pasa; backend `npm test` (si existe) o `node index.js` arranca limpio.
11. **`flutter analyze`**: cero warnings.

---

## Orden de ejecución sugerido

1. Crear ambos worktrees.
2. Backend polish (corto): helmet + rate-limit + rotar JWT_SECRET + README. Commit.
3. Flutter — modelo User y config base (api_config, api_client, token_storage). Commit.
4. Flutter — `BackendAuthService` + tests del servicio. Commit.
5. Flutter — refactor `RemoteAuthRepository` + `restoreSession` + provider. Commit.
6. Flutter — UI perfil + upload imagen. Commit.
7. Pruebas manuales contra backend dockerizado.
8. PRs por separado en cada repo (cada worktree → su propia rama).
