// ============================================================
// FILE: profile_provider.dart
// PURPOSE: Persiste los datos del perfil del usuario a nivel global
//          usando Riverpod, para que sobrevivan la navegación.
//
// CONCEPTS TAUGHT:
//   - Riverpod global state vs local state: A diferencia de un
//     StatefulWidget donde el estado se pierde al salir de la
//     pantalla, un NotifierProvider mantiene el estado mientras
//     la app esté viva. Esto permite navegar entre tabs y volver
//     al perfil sin perder los datos guardados.
//
//   - Map<String, dynamic>? como estado: Null significa que el
//     usuario aún no ha completado su perfil. Un Map con datos
//     significa que ya guardó al menos una vez.
//
//   - Separación de responsabilidades: Este provider solo almacena
//     datos guardados. La validación del formulario sigue en el
//     BLoC (ProfileFormBloc), que es creado y destruido con la
//     pantalla. Esto demuestra que BLoC y Riverpod pueden coexistir.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  /// Guarda los datos del perfil. Crea un nuevo Map inmutable.
  void save(Map<String, dynamic> data) {
    state = Map.unmodifiable(data);
  }

  /// Limpia los datos del perfil.
  void clear() => state = null;
}

final profileProvider = NotifierProvider<ProfileNotifier, Map<String, dynamic>?>(
  ProfileNotifier.new,
);
