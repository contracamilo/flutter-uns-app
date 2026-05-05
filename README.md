# UniSalle

Flutter e-commerce boilerplate con arquitectura feature-based, Riverpod para estado y GoRouter para navegación.

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.35.0
- Dart SDK >= 3.9.0
- [Node.js](https://nodejs.org/) >= 20.19.0 (para OpenSpec)
- Android Studio / Xcode (según plataforma objetivo)

## Instalación

```bash
# Clonar el repositorio
git clone https://github.com/contracamilo/flutter-uns-app.git
cd flutter-uns-app

# Instalar dependencias de Flutter
flutter pub get

# (Opcional) Instalar OpenSpec para spec-driven development
npm install -g @fission-ai/openspec@latest
```

## Levantar el proyecto

```bash
# Verificar que el entorno está configurado correctamente
flutter doctor

# Ejecutar en modo debug
flutter run

# Ejecutar en un dispositivo específico
flutter devices          # listar dispositivos disponibles
flutter run -d <device>  # ejecutar en dispositivo específico

# Ejecutar en Chrome (web)
flutter run -d chrome

# Ejecutar en simulador iOS
open -a Simulator
flutter run -d ios

# Ejecutar en emulador Android
flutter emulators --launch <emulator_id>
flutter run -d android
```

## Comandos útiles

```bash
# Análisis estático de código
flutter analyze

# Ejecutar tests
flutter test

# Build de producción
flutter build apk        # Android
flutter build ios         # iOS
flutter build web         # Web
```

## Estructura del proyecto

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp con routing y theming
├── core/                  # Infraestructura base
│   ├── constants/         # Tamaños y espaciado
│   ├── extensions/        # Extensiones de BuildContext
│   ├── router/            # GoRouter (navegación por tabs)
│   └── theme/             # Material 3, light/dark mode
├── data/                  # Capa de datos
│   ├── mock_products.dart # Datos mock
│   └── repositories/      # Patrón repository
├── models/                # Modelos de dominio (Product, CartItem)
├── features/              # Módulos por feature (catalog, cart, etc.)
└── shared/                # Widgets reutilizables
```

## Spec-Driven Development (OpenSpec)

Este proyecto usa [OpenSpec](https://github.com/Fission-AI/OpenSpec) para planificar features antes de implementarlas.

```bash
# Crear un nuevo feature
/opsx:new <feature-name>

# Generar artefactos de planificación
/opsx:ff

# Implementar tareas planificadas
/opsx:apply

# Archivar feature completado
/opsx:archive
```

## Tech Stack

- **Flutter** - Framework UI multiplataforma
- **Riverpod** - Estado reactivo (Notifier + AsyncNotifier)
- **GoRouter** - Navegación declarativa con tabs
- **Google Fonts** - Tipografía
- **intl** - Formateo de números y monedas
- **Dio + flutter_secure_storage** - HTTP client con interceptor JWT y persistencia segura del token

## Backend de email/password

El login con email/contraseña habla con un backend Node.js + Express + MySQL que vive en el repo hermano [`unisalle_backend`](https://github.com/contracamilo/unisalle-backend). Los flujos de Google y GitHub siguen sobre Firebase.

### 1. Levantar el backend

Desde el directorio del backend:

```bash
cd ../unisalle_backend
cp .env.example .env   # ajusta DB_PASSWORD y JWT_SECRET
docker compose up --build
```

El backend queda escuchando en `http://localhost:3000` y bindea `0.0.0.0` para que el dispositivo móvil pueda alcanzarlo en LAN.

### 2. Configurar la URL base en la app

Por defecto la app resuelve la URL según la plataforma:

| Plataforma | URL por defecto |
|------------|----------------|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator / desktop / web | `http://localhost:3000` |

Para un dispositivo físico en LAN, sobreescribir vía `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

O añadir la clave en `env/dev.json` y usar `--dart-define-from-file=env/dev.json` (ya configurado en `.vscode/launch.json`).

### 3. Endpoints consumidos

| Método | Endpoint | Cuándo se usa |
|--------|----------|---------------|
| POST | `/api/auth/register` | Pantalla de registro |
| POST | `/api/auth/login` | Pantalla de login |
| GET | `/api/users/me` | `restoreSession()` al arrancar la app |
| PUT | `/api/users/:id/image` | Botón "Cambiar foto" en perfil |

El JWT se guarda en `flutter_secure_storage` (Keychain en iOS, EncryptedSharedPreferences en Android) y se inyecta como `Authorization: Bearer <token>` por el interceptor de Dio.

### 4. Flujos OAuth (Google / GitHub)

Los OAuth siguen viviendo en Firebase Auth. Sus usuarios NO existen en MySQL — sus roles del backend estarán vacíos. Para cambiar la foto, el usuario debe hacerlo desde su cuenta de Google/GitHub.

### 5. Troubleshooting

**Android — `CleartextNotPermitted`**: el backend dev sirve HTTP. La app trae un `network_security_config.xml` que permite cleartext sólo para `localhost`, `10.0.2.2` y `127.0.0.1`. Para otra IP de LAN, añadirla en `android/app/src/main/res/xml/network_security_config.xml`.

**iOS — `NSURLErrorDomain` -1022**: `NSAllowsLocalNetworking=true` está activo en `Info.plist`. Cubre 10.x / 192.168.x / .local. Para otra red, añadir el host en `NSAppTransportSecurity → NSExceptionDomains`.

**`Connection refused`**: el backend no está corriendo, o la app está usando una URL incorrecta. Verifica con `curl http://<URL>/api/health`.
