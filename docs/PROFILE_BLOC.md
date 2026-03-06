# Guía del Feature — Perfil de Usuario (BLoC + RxDart + Riverpod)

Documentación técnica y pedagógica de la pantalla de perfil, que implementa
el patrón **BLoC puro con RxDart** para validación reactiva de formularios
y **Riverpod** para persistencia del estado entre navegaciones.

---

## Índice

1. [Objetivo pedagógico](#1-objetivo-pedagógico)
2. [Arquitectura BLoC puro + Riverpod](#2-arquitectura-bloc-puro--riverpod)
3. [Estructura de archivos](#3-estructura-de-archivos)
4. [ProfileFormBloc en detalle](#4-profileformbloc-en-detalle)
5. [ProfileProvider — persistencia global](#5-profileprovider--persistencia-global)
6. [Flujo de datos](#6-flujo-de-datos)
7. [Validaciones](#7-validaciones)
8. [Modos vista y edición](#8-modos-vista-y-edición)
9. [Integración con la UI](#9-integración-con-la-ui)
10. [Navegación](#10-navegación)
11. [Decisiones de diseño y lecciones aprendidas](#11-decisiones-de-diseño-y-lecciones-aprendidas)
12. [Referencia de archivos](#12-referencia-de-archivos)

---

## 1. Objetivo pedagógico

Este feature demuestra:

- El patrón **BLoC (Business Logic Component)** en su forma pura con RxDart
  para validación reactiva de formularios.
- La **coexistencia de BLoC y Riverpod** en una misma pantalla.
- **Dos modos de UI** (vista read-only y edición) en un solo widget.
- **Persistencia de estado global** con Riverpod `NotifierProvider` para que
  los datos sobrevivan la navegación.
- **Validación bajo demanda** con `triggerValidation()` para mostrar errores
  solo cuando el usuario intenta guardar.

### ¿Por qué BLoC puro y no `flutter_bloc`?

| Aspecto | BLoC puro (este feature) | flutter_bloc |
|---|---|---|
| Dependencias | Solo `rxdart` | `bloc` + `flutter_bloc` |
| Clase base | Ninguna | `Bloc<Event, State>` |
| Comunicación | `BehaviorSubject` + `StreamBuilder` | `BlocBuilder` / `BlocListener` |
| Boilerplate | Bajo (sin eventos ni estados tipados) | Medio (requiere clases Event/State) |
| Caso de uso ideal | Formularios con validación reactiva | Lógica de negocio compleja con eventos discretos |

El enfoque puro permite entender **qué hace RxDart por debajo** antes de
usar abstracciones de alto nivel.

---

## 2. Arquitectura BLoC puro + Riverpod

```
┌─────────────────────────────────────────────────────────────┐
│                        UniSalle App                          │
│                                                              │
│  ┌──────────────────┐         ┌───────────────────────────┐  │
│  │     Riverpod     │         │       BLoC puro           │  │
│  │                  │         │                           │  │
│  │  AuthProvider    │◄────────│  ProfileFormBloc           │  │
│  │  CartProvider    │  lee    │  (BehaviorSubject +        │  │
│  │  FavoritesProvider│ user   │   Rx.combineLatest)        │  │
│  │  ProfileProvider │◄────────│                           │  │
│  │  (persiste datos)│ guarda  │  Validación local del form │  │
│  └──────────────────┘         └───────────────────────────┘  │
│                                                              │
│  Estado global,              Estado local del form,          │
│  persiste entre              vive solo mientras la           │
│  pantallas                   pantalla está montada           │
└─────────────────────────────────────────────────────────────┘
```

**Cuándo usar cada uno:**

- **Riverpod (`profileProvider`)**: Datos guardados del perfil que deben
  persistir entre navegaciones. Cualquier pantalla puede leerlos.
- **BLoC puro (`ProfileFormBloc`)**: Validación reactiva campo por campo
  del formulario. Se crea al montar la pantalla y se destruye al salir.
  Se pre-carga desde el provider al iniciar.

---

## 3. Estructura de archivos

```
lib/features/profile/
├── presentation/
│   ├── bloc/
│   │   └── profile_form_bloc.dart    ← Lógica de validación (clase Dart pura)
│   ├── screens/
│   │   └── profile_screen.dart       ← UI vista/edición (ConsumerStatefulWidget)
│   └── widgets/
│       └── profile_text_field.dart   ← TextField con StreamBuilder reutilizable
└── providers/
    └── profile_provider.dart         ← NotifierProvider para persistencia global
```

---

## 4. ProfileFormBloc en detalle

### 4.1 BehaviorSubject

`BehaviorSubject<String>` es un `StreamController` especial de RxDart:

```dart
final _name = BehaviorSubject<String>.seeded('');
final _birthDate = BehaviorSubject<DateTime?>.seeded(null);
final _validationTriggered = BehaviorSubject<bool>.seeded(false);
```

| Característica | StreamController | BehaviorSubject |
|---|---|---|
| Valor inicial | No tiene | Sí (`.seeded('')`) |
| Acceso al último valor | No | Sí (`.value`) |
| Emisión a nuevos listeners | Solo valores futuros | Emite el último valor inmediatamente |
| Múltiples listeners | No (por defecto) | Sí (es broadcast) |

### 4.2 Streams de validación con `_validationTriggered`

Los streams de error combinan el valor del campo con el flag de validación:

```dart
Stream<String?> get nameError => Rx.combineLatest2(
      _name.stream,
      _validationTriggered.stream,
      (String value, bool triggered) => _validateName(value, triggered),
    );
```

- Si el campo está **vacío** y `triggered == false` → `null` (sin error visible)
- Si el campo está **vacío** y `triggered == true` → mensaje de error ("El nombre es requerido")
- Si el campo tiene **contenido inválido** → error siempre visible (independiente de `triggered`)

### 4.3 `triggerValidation()` y `resetValidation()`

```dart
void triggerValidation() {
  _validationTriggered.add(true);
  // Re-emitir todos los subjects para forzar recálculo
  _name.add(_name.value);
  _age.add(_age.value);
  // ... todos los campos
}

void resetValidation() {
  _validationTriggered.add(false);
}
```

**Uso:** Cuando el usuario toca "Guardar" sin llenar todos los campos,
la UI llama `triggerValidation()` para que todos los errores se muestren
de golpe. Al cancelar o guardar exitosamente, se llama `resetValidation()`.

### 4.4 combineLatestList para `isFormValid`

```dart
Stream<bool> get isFormValid => Rx.combineLatestList<String?>([
      nameError, ageError, sexError, phoneError,
      birthCityError, careerError, semesterError, birthDateError,
    ]).map((errors) =>
        errors.every((e) => e == null) &&
        _name.value.isNotEmpty &&
        _age.value.isNotEmpty &&
        // ... todos los campos no vacíos
        _birthDate.value != null);
```

### 4.5 Fecha de nacimiento

```dart
final _birthDate = BehaviorSubject<DateTime?>.seeded(null);

Stream<String?> get birthDateError => Rx.combineLatest2(
      _birthDate.stream,
      _validationTriggered.stream,
      (DateTime? value, bool triggered) => _validateBirthDate(value, triggered),
    );

Stream<DateTime?> get birthDateStream => _birthDate.stream;
DateTime? get birthDateValue => _birthDate.value;

void changeBirthDate(DateTime? value) => _birthDate.add(value);
```

Validaciones de fecha:
- `null` y no triggered → sin error
- `null` y triggered → "Selecciona tu fecha de nacimiento"
- Fecha futura → "La fecha debe ser en el pasado"
- Edad < 16 → "Debes tener al menos 16 años"
- Edad > 99 → "Edad máxima: 99 años"

### 4.6 `submitForm()` retorna `Map<String, dynamic>`

```dart
Map<String, dynamic> submitForm() {
  return {
    'nombre': _name.value,
    'edad': _age.value,
    'sexo': _sex.value,
    'telefono': _phone.value,
    'ciudadNacimiento': _birthCity.value,
    'carrera': _career.value,
    'semestre': _semester.value,
    'fechaNacimiento': _birthDate.value?.toIso8601String(),
  };
}
```

> Retorna `Map<String, dynamic>` (no `Map<String, String>`) porque
> `fechaNacimiento` puede ser `null`.

---

## 5. ProfileProvider — persistencia global

```dart
// lib/features/profile/providers/profile_provider.dart

class ProfileNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void save(Map<String, dynamic> data) {
    state = Map.unmodifiable(data);
  }

  void clear() => state = null;
}

final profileProvider = NotifierProvider<ProfileNotifier, Map<String, dynamic>?>(
  ProfileNotifier.new,
);
```

**Por qué un provider separado del BLoC:**

- El BLoC maneja validación reactiva (streams, RxDart) — estado efímero del formulario.
- El provider guarda los datos **ya validados** — estado persistente entre navegaciones.
- Sigue el mismo patrón que `cartProvider` y `favoritesProvider`.

**Flujo:**
1. Al abrir la pantalla, `_preloadBloc()` lee `ref.read(profileProvider)` y alimenta el BLoC.
2. Al guardar, `_onSubmit()` llama `ref.read(profileProvider.notifier).save(data)`.
3. El modo vista usa `ref.watch(profileProvider)` para mostrar los datos.

---

## 6. Flujo de datos

```
  ┌─────────────────┐
  │  profileProvider │ ◄── Estado global (Riverpod)
  │  Map<String,     │     Persiste entre navegaciones
  │   dynamic>?      │
  └────┬─────▲──────┘
       │     │
  lee al     │ guarda al
  montar     │ hacer submit
       │     │
  ┌────▼─────┴──────┐
  │ ProfileFormBloc  │ ◄── Estado local (BLoC/RxDart)
  │ BehaviorSubjects │     Vive mientras la pantalla está montada
  └────┬─────▲──────┘
       │     │
  streams    │ change*()
  de error   │
       │     │
  ┌────▼─────┴──────┐
  │  ProfileScreen   │ ◄── UI (ConsumerStatefulWidget)
  │  StreamBuilders  │     Modo vista: lee provider
  │  + ref.watch     │     Modo edición: escucha streams del BLoC
  └─────────────────┘
```

### Flujo detallado: edición de un campo

```
  Usuario escribe        BLoC procesa             UI reacciona
  ─────────────          ────────────             ────────────

  TextField.onChanged
        │
        ▼
  bloc.changeName("Jo")
        │
        ▼
  _name.add("Jo")       ← BehaviorSubject emite "Jo"
        │
        ├──► nameError stream ──► combineLatest2(value, triggered)
        │         │                      │
        │         ▼                      ▼
        │    "Mínimo 2 chars"    StreamBuilder reconstruye
        │    (si triggered       TextField con errorText
        │     o len < 2)
        │
        └──► isFormValid stream ──► combineLatestList
                                          │
                                          ▼
                                   StreamBuilder reconstruye
                                   botón (enabled/disabled)
```

### Flujo detallado: guardar perfil

```
  1. Usuario toca "Guardar"
        │
        ├── isValid == true:
        │       │
        │       ▼
        │   _bloc.submitForm() → Map<String, dynamic>
        │       │
        │       ▼
        │   ref.read(profileProvider.notifier).save(data)
        │       │
        │       ▼
        │   setState(() => _isEditing = false)
        │       │
        │       ▼
        │   _bloc.resetValidation()
        │       │
        │       ▼
        │   SnackBar de confirmación
        │
        └── isValid == false:
                │
                ▼
            _bloc.triggerValidation()
                │
                ▼
            Todos los campos vacíos muestran error
```

---

## 7. Validaciones

| Campo | Regla | Error si vacío (triggered) | Error de formato |
|---|---|---|---|
| **Nombre** | ≥ 2 caracteres | "El nombre es requerido" | "El nombre debe tener al menos 2 caracteres" |
| **Edad** | Numérico, 16–99 | "La edad es requerida" | "Ingresa un número válido" / "La edad debe estar entre 16 y 99" |
| **Fecha nacimiento** | Pasado, edad 16–99 | "Selecciona tu fecha de nacimiento" | "La fecha debe ser en el pasado" / "Debes tener al menos 16 años" / "Edad máxima: 99 años" |
| **Sexo** | Selección requerida | "Selecciona una opción" | — |
| **Teléfono** | Solo dígitos, 10 chars | "El teléfono es requerido" | "Solo se permiten dígitos" / "El teléfono debe tener 10 dígitos" |
| **Ciudad** | ≥ 3 caracteres | "La ciudad es requerida" | "La ciudad debe tener al menos 3 caracteres" |
| **Carrera** | Selección requerida | "Selecciona una carrera" | — |
| **Semestre** | Numérico, 1–12 | "El semestre es requerido" | "Ingresa un número válido" / "El semestre debe estar entre 1 y 12" |

**Comportamiento de validación:**
- **Estado inicial**: Campos vacíos no muestran error (UX limpia).
- **Mientras escribe**: Errores de formato aparecen en tiempo real.
- **Al tocar "Guardar" sin completar**: `triggerValidation()` muestra todos los errores de campos vacíos.
- **Al cancelar o guardar OK**: `resetValidation()` limpia el flag.

---

## 8. Modos vista y edición

### Modo Vista (read-only)

- **Sin perfil guardado**: Icono grande + mensaje "Toca el icono de editar para completar tu perfil".
- **Con perfil guardado**: Card con `ListTile`s mostrando cada campo (icono, label, valor).
- **AppBar**: Título "Mi Perfil", action `Icons.edit_outlined` para entrar en edición.
- **Back button**: Navega al catálogo normalmente.

### Modo Edición (formulario)

- **AppBar**: Título "Editar Perfil", action "Cancelar" (TextButton) para volver a vista.
- **Campos**: `ProfileTextField` para texto, `DropdownButtonFormField` para sexo/carrera, `InkWell` + `InputDecorator` + `showDatePicker` para fecha.
- **Botón "Guardar"**: Siempre habilitado — si inválido llama `triggerValidation()`, si válido guarda.
- **Back button**: Interceptado con `PopScope` → diálogo "Cambios sin guardar" con opciones "Continuar editando" / "Salir".
- **Pre-carga**: Al entrar en edición, los campos se pre-cargan del provider (si hay datos guardados).

### PopScope para cambios sin guardar

```dart
PopScope(
  canPop: !_isEditing,  // Solo permite pop automático en modo vista
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;  // Ya se hizo pop (modo vista)
    final leave = await _showUnsavedChangesDialog();
    if (leave && mounted) {
      if (context.mounted) context.pop();
    }
  },
  child: Scaffold(...)
)
```

---

## 9. Integración con la UI

### 9.1 ConsumerStatefulWidget

La pantalla usa `ConsumerStatefulWidget` (no `StatefulWidget`) para tener
acceso a `ref` directamente:

```dart
class ProfileScreen extends ConsumerStatefulWidget { ... }

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ref está disponible directamente, sin ProviderScope.containerOf
  void _onSubmit() {
    final data = _bloc.submitForm();
    ref.read(profileProvider.notifier).save(data);
  }

  @override
  Widget build(BuildContext context) {
    final savedProfile = ref.watch(profileProvider); // reactivo
    // ...
  }
}
```

### 9.2 Pre-carga del BLoC desde el provider

```dart
void _preloadBloc() {
  final saved = ref.read(profileProvider);
  if (saved != null) {
    _bloc.changeName(saved['nombre'] as String? ?? '');
    _bloc.changeAge(saved['edad'] as String? ?? '');
    // ... todos los campos
    final birthDateStr = saved['fechaNacimiento'] as String?;
    if (birthDateStr != null) {
      _bloc.changeBirthDate(DateTime.tryParse(birthDateStr));
    }
  } else {
    // Si no hay perfil guardado, pre-cargar nombre del user auth
    final user = ref.read(authProvider).valueOrNull;
    if (user != null && user.name.isNotEmpty) {
      _bloc.setInitialName(user.name);
    }
  }
}
```

### 9.3 Date picker con InputDecorator

```dart
StreamBuilder<String?>(
  stream: _bloc.birthDateError,
  builder: (context, errorSnapshot) {
    return StreamBuilder<DateTime?>(
      stream: _bloc.birthDateStream,
      builder: (context, dateSnapshot) {
        final date = dateSnapshot.data;
        final formattedDate = date != null
            ? DateFormat('dd/MM/yyyy').format(date) : null;
        return InkWell(
          onTap: _pickBirthDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Fecha de nacimiento',
              errorText: errorSnapshot.hasData ? errorSnapshot.data : null,
            ),
            child: Text(formattedDate ?? 'Seleccionar fecha'),
          ),
        );
      },
    );
  },
)
```

### 9.4 Dropdowns: cuidado con `initialValue` vacío

Los `DropdownButtonFormField` requieren que `initialValue` sea `null` o un
valor que exista en los items. Un string vacío `''` causa un assertion error:

```dart
// ❌ INCORRECTO — '' no está en los items del dropdown
initialValue: _bloc.submitForm()['sexo'] as String?,  // puede ser ''

// ✅ CORRECTO — retorna null si el valor está vacío
String? _sexInitialValue() {
  final v = _bloc.submitForm()['sexo'] as String?;
  return (v != null && v.isNotEmpty) ? v : null;
}
```

---

## 10. Navegación

### Acceso al perfil

Icono en el `AppBar` del catálogo usando `pushNamed` (no `goNamed`):

```dart
// catalog_app_bar.dart
IconButton(
  icon: const Icon(Icons.person_outline),
  tooltip: 'Mi perfil',
  onPressed: () => context.pushNamed(RouteNames.profile),
)
```

**¿Por qué `pushNamed` y no `goNamed`?**

- `goNamed` → **reemplaza** la pila de navegación completa. Como `/profile`
  está fuera del `StatefulShellRoute`, esto destruye el shell (bottom nav)
  y el usuario no puede volver a otras tabs.
- `pushNamed` → **empuja** sobre la pila actual. El shell queda debajo,
  el back button funciona, y al volver el usuario sigue en la tab anterior.

### Ruta

```dart
// app_router.dart — fuera del StatefulShellRoute (sin bottom nav)
GoRoute(
  path: '/profile',
  name: RouteNames.profile,
  builder: (context, state) => const ProfileScreen(),
),
```

### Mapa de rutas

```
/welcome       → WelcomeScreen       (pública)
/login         → LoginScreen         (pública)
/register      → RegisterScreen      (pública)
/profile       → ProfileScreen       (auth required, sin tabs, push)
/catalog       → CatalogScreen       (auth required)
  /product/:id → ProductDetailScreen (auth required, nested)
/favorites     → FavoritesScreen     (auth required)
/cart          → CartScreen          (auth required)
```

---

## 11. Decisiones de diseño y lecciones aprendidas

### `goNamed` vs `pushNamed` para rutas fuera del shell

**Problema:** Usar `context.goNamed(RouteNames.profile)` para una ruta
fuera del `StatefulShellRoute` destruye el shell de navegación (bottom nav).
El usuario pierde la capacidad de cambiar de tab.

**Solución:** Usar `context.pushNamed(RouteNames.profile)` para que la
pantalla se empuje sobre la pila actual. El back button vuelve al catálogo.

### Estado local (BLoC) vs global (Provider) para formularios

**Problema:** Los datos del formulario se perdían al navegar porque el BLoC
y `_savedProfile` eran estado local del `StatefulWidget`, destruidos en `dispose()`.

**Solución:** Separar responsabilidades:
- **BLoC (local)**: Validación reactiva del formulario. Se recrea al abrir la pantalla.
- **Provider (global)**: Datos guardados. Persisten entre navegaciones.
- Al montar la pantalla, el BLoC se pre-carga desde el provider.

### `DropdownButtonFormField` y valores vacíos

**Problema:** Pasar `initialValue: ''` (string vacío del BLoC inicial) a un
dropdown cuyos items son `['Masculino', 'Femenino', 'Otro']` causa un
assertion error porque `''` no está en la lista de items.

**Solución:** Helpers que convierten strings vacíos a `null`:

```dart
String? _sexInitialValue() {
  final v = _bloc.submitForm()['sexo'] as String?;
  return (v != null && v.isNotEmpty) ? v : null;
}
```

### `triggerValidation()` para UX limpia

**Problema:** Mostrar errores de "campo requerido" desde el inicio es mala UX.
Pero el botón "Guardar" debe indicar qué campos faltan.

**Solución:** `_validationTriggered` controla si los errores de vacío se muestran.
- Inicio: `false` → formulario limpio.
- Tap "Guardar" inválido: `triggerValidation()` → `true` → todos los errores visibles.
- Cancelar/guardar OK: `resetValidation()` → `false`.

---

## 12. Referencia de archivos

| Archivo | Propósito |
|---|---|
| `lib/features/profile/presentation/bloc/profile_form_bloc.dart` | BLoC con BehaviorSubjects, validadores, triggerValidation y combineLatest |
| `lib/features/profile/presentation/screens/profile_screen.dart` | UI vista/edición (ConsumerStatefulWidget + StreamBuilders + ref) |
| `lib/features/profile/presentation/widgets/profile_text_field.dart` | TextField reutilizable con stream de errores |
| `lib/features/profile/providers/profile_provider.dart` | NotifierProvider para persistencia global del perfil |
| `lib/core/router/route_names.dart` | Constante `RouteNames.profile` |
| `lib/core/router/app_router.dart` | Ruta `/profile` (GoRoute fuera del shell) |
| `lib/features/catalog/presentation/widgets/catalog_app_bar.dart` | IconButton con `pushNamed` para acceso al perfil |
| `pubspec.yaml` | Dependencias `rxdart: ^0.28.0`, `intl: ^0.20.2` |

### Diagrama de dependencias

```
profile_form_bloc.dart
  └── rxdart (BehaviorSubject, Rx.combineLatest2, Rx.combineLatestList)

profile_text_field.dart
  └── app_sizes.dart (AppSizes.p16)

profile_provider.dart
  └── flutter_riverpod (NotifierProvider)

profile_screen.dart
  ├── profile_form_bloc.dart (crea/destruye el BLoC, pre-carga desde provider)
  ├── profile_text_field.dart (widget de campo)
  ├── profile_provider.dart (ref.watch para vista, ref.read para guardar)
  ├── auth_provider.dart (lee usuario autenticado para pre-carga)
  ├── intl (DateFormat para formateo de fechas)
  ├── go_router (PopScope, context.pop)
  ├── app_sizes.dart (espaciado)
  └── build_context_extensions.dart (context.colorScheme, context.textTheme)

catalog_app_bar.dart
  ├── route_names.dart (RouteNames.profile)
  └── go_router (context.pushNamed)

app_router.dart
  ├── route_names.dart (RouteNames.profile)
  └── profile_screen.dart (ProfileScreen)
```
