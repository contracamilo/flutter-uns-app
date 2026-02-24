# Guía de configuración — Autenticación OAuth

Instrucciones paso a paso para activar Google Sign-In y GitHub OAuth en UniSalle.

---

## Índice

1. [Google Sign-In](#1-google-sign-in)
2. [GitHub OAuth](#2-github-oauth)
3. [Integración con backend](#3-integración-con-backend)
4. [Activar `RemoteAuthRepository`](#4-activar-remoteauthrepository)
5. [Referencia de archivos](#5-referencia-de-archivos)

---

## 1. Google Sign-In

Google Sign-In requiere un proyecto en **Firebase** (recomendado) o en
**Google Cloud Console** directamente. Firebase simplifica la configuración
de los archivos de plataforma.

### 1.1 Crear proyecto en Firebase

1. Ve a [console.firebase.google.com](https://console.firebase.google.com).
2. **"Agregar proyecto"** → ponle nombre → continúa.
3. En el panel del proyecto, haz clic en **"Autenticación"** → **"Comenzar"**.
4. Pestaña **"Método de inicio de sesión"** → activa **Google** → guarda.

### 1.2 Configurar iOS

1. En Firebase Console → Configuración del proyecto → **"Agregar app"** → iOS.
2. **Bundle ID**: usa el bundle ID de tu app (Xcode → Runner → General → Bundle Identifier).
   Por defecto en este proyecto: `com.example.unisalle` (cámbialo a uno único tuyo).
3. Descarga el archivo **`GoogleService-Info.plist`**.
4. **Arrastra** el archivo a `ios/Runner/` en Xcode (asegúrate de que "Copy items if needed" esté marcado).
5. En `ios/Runner/Info.plist`, reemplaza `YOUR_REVERSED_CLIENT_ID` con el valor del campo `REVERSED_CLIENT_ID` dentro del archivo `.plist` descargado.

```xml
<!-- ios/Runner/Info.plist — ya está preparado, solo reemplaza el valor -->
<string>YOUR_REVERSED_CLIENT_ID</string>
<!-- Ejemplo real: -->
<string>com.googleusercontent.apps.123456789-abcdefgh</string>
```

### 1.3 Configurar Android

1. En Firebase Console → **"Agregar app"** → Android.
2. **Package name**: el que está en `android/app/build.gradle` → `applicationId`.
   Por defecto: `com.example.unisalle`.
3. **SHA-1 de debug** (necesario para Google Sign-In):
   ```bash
   # Desde la raíz del proyecto
   keytool -list -v \
     -alias androiddebugkey \
     -keystore ~/.android/debug.keystore \
     -storepass android -keypass android
   ```
   Copia el SHA-1 y pégalo en Firebase.
4. Descarga **`google-services.json`** y colócalo en `android/app/`.
5. Aplica el plugin de Google Services en los Gradle:

   **`android/build.gradle`** (project-level):
   ```groovy
   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.4.2'
     }
   }
   ```

   **`android/app/build.gradle`** (app-level), al final del archivo:
   ```groovy
   apply plugin: 'com.google.gms.google-services'
   ```

### 1.4 Verificar

```bash
flutter run -d <device>
# Pulsa "Continuar con Google" → debe aparecer el selector de cuentas nativo
```

---

## 2. GitHub OAuth

GitHub usa OAuth 2.0 Authorization Code Flow. El cliente abre un browser
in-app; el servidor de GitHub redirige de vuelta a la app con un `code`.

### 2.1 Crear GitHub OAuth App

1. Ve a [github.com/settings/developers](https://github.com/settings/developers).
2. **"New OAuth App"**.
3. Rellena los campos:
   | Campo | Valor |
   |---|---|
   | Application name | UniSalle (o el que prefieras) |
   | Homepage URL | `https://tu-dominio.com` (o `http://localhost`) |
   | **Authorization callback URL** | `unisalle://auth/callback` |
4. Haz clic en **"Register application"**.
5. Copia el **Client ID** que aparece.
6. (Opcional) Genera un **Client Secret** — solo lo necesitará el backend.

### 2.2 Configurar la app

Abre `lib/core/config/auth_config.dart` y reemplaza el placeholder:

```dart
abstract class GithubAuthConfig {
  static const String clientId = 'YOUR_GITHUB_CLIENT_ID'; // 👈 Pega tu Client ID aquí
  // ...
}
```

### 2.3 Verificar callback en iOS

El `Info.plist` ya tiene el scheme `unisalle` registrado. No necesitas
cambiar nada si usas el scheme por defecto.

### 2.4 Verificar callback en Android

`AndroidManifest.xml` ya tiene configurado el `CallbackActivity` con
`android:scheme="unisalle"`. Igualmente, no requiere cambios con el scheme por defecto.

### 2.5 Verificar

```bash
flutter run -d <device>
# Pulsa "Continuar con GitHub" → debe abrir github.com en browser in-app
# Después de autorizar → debe volver a la app
```

> **Estado actual**: El flujo llega hasta capturar el `code` de GitHub.
> El siguiente paso (intercambio por access_token) requiere el backend (§3).

---

## 3. Integración con backend

### 3.1 Por qué es necesario

| Proveedor | Qué hace el cliente | Qué hace el backend |
|---|---|---|
| **Google** | Obtiene `idToken` (JWT de Google) | Verifica JWT, crea usuario en DB, emite session token |
| **GitHub** | Obtiene `code` de autorización | Intercambia `code` por `access_token`, llama `/user` de GitHub API, crea usuario en DB, emite session token |
| **Email** | Envía credenciales | Verifica, crea sesión, devuelve session token |

### 3.2 Endpoints sugeridos

```
POST /auth/google
  Body: { "id_token": "eyJ..." }
  Response: { "session_token": "...", "user": { "id": "...", "name": "...", "email": "..." } }

POST /auth/github/callback
  Body: { "code": "abc123" }
  Response: { "session_token": "...", "user": { ... } }

POST /auth/login
  Body: { "email": "...", "password": "..." }
  Response: { "session_token": "...", "user": { ... } }

POST /auth/register
  Body: { "name": "...", "email": "...", "password": "..." }
  Response: { "session_token": "...", "user": { ... } }

POST /auth/logout
  Headers: Authorization: Bearer <session_token>
  Response: 204 No Content
```

### 3.3 Implementar en RemoteAuthRepository

Busca los bloques `// TODO` en `remote_auth_repository.dart` y descomenta
el código de ejemplo. Antes de eso:

1. Añade `http` a `pubspec.yaml`:
   ```yaml
   http: ^1.2.2
   ```
2. Crea `lib/core/config/api_config.dart`:
   ```dart
   abstract class ApiConfig {
     static const String baseUrl = 'https://tu-backend.com/api/v1';
   }
   ```
3. Implementa `_saveSessionToken` / `_clearSessionToken` usando
   `flutter_secure_storage` para persistir el token de forma segura:
   ```yaml
   flutter_secure_storage: ^9.2.2
   ```

### 3.4 Persistencia de sesión

Para que el usuario no tenga que loguearse en cada arranque, guarda el
session token y restáuralo en `AuthNotifier.build()`:

```dart
@override
Future<User?> build() async {
  final token = await secureStorage.read(key: 'session_token');
  if (token == null) return null;

  // Verificar token contra el backend
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/auth/me'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) return null;

  return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}
```

---

## 4. Activar `RemoteAuthRepository`

Una vez que el backend esté listo, cambia **una sola línea** en
`lib/features/auth/providers/auth_provider.dart`:

```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Antes (desarrollo):
  return MockAuthRepository();

  // Después (producción):
  // return RemoteAuthRepository();
});
```

> Para email/password también debes implementar los métodos correspondientes
> en `RemoteAuthRepository` (los TODOs están documentados en el archivo).

---

## 5. Referencia de archivos

| Archivo | Propósito |
|---|---|
| `lib/core/config/auth_config.dart` | Client IDs y configuración OAuth |
| `lib/features/auth/data/auth_repository.dart` | Interfaz abstracta |
| `lib/features/auth/data/mock_auth_repository.dart` | Implementación mock (desarrollo) |
| `lib/features/auth/data/remote_auth_repository.dart` | Implementación real con TODOs |
| `lib/features/auth/providers/auth_provider.dart` | `authRepositoryProvider` (punto de swap) |
| `ios/Runner/Info.plist` | URL schemes de iOS (GitHub + Google) |
| `android/app/src/main/AndroidManifest.xml` | Permisos y `CallbackActivity` de Android |
| `ios/Runner/GoogleService-Info.plist` | **No incluido** — descárgalo de Firebase |
| `android/app/google-services.json` | **No incluido** — descárgalo de Firebase |

---

## Estado resumido

| Feature | SDK integrado | Config plataforma | Backend |
|---|---|---|---|
| Google Sign-In | ✅ `google_sign_in` | ⚠️ Archivos Firebase pendientes | ⏳ TODO |
| GitHub OAuth | ✅ `flutter_web_auth_2` | ✅ Schemes configurados | ⏳ TODO |
| Email/Password | — | — | ⏳ TODO |
| Persistencia de sesión | — | — | ⏳ TODO |
