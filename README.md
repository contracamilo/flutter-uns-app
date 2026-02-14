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
