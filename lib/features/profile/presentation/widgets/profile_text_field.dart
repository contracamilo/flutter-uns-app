// ============================================================
// FILE: profile_text_field.dart
// PURPOSE: TextField reutilizable que escucha un Stream<String?>
//          para mostrar errores de validación en tiempo real.
//
// CONCEPTS TAUGHT:
//   - StreamBuilder: Widget que se reconstruye cada vez que un
//     Stream emite un nuevo valor. Aquí escucha el stream de
//     errores del BLoC para actualizar el errorText del campo.
//
//   - Separación UI/lógica: Este widget NO conoce las reglas de
//     validación. Solo recibe un stream de errores y lo muestra.
//     La lógica vive en ProfileFormBloc.
//
//   - InputDecoration.errorText: Cuando es non-null, Flutter
//     automáticamente muestra el texto en rojo debajo del campo
//     y cambia el borde a rojo. Cuando es null, el campo luce normal.
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.errorStream,
    required this.onChanged,
    this.prefixIcon,
    this.keyboardType,
    this.initialValue,
  });

  /// Etiqueta que se muestra como label del campo.
  final String label;

  /// Stream de errores del BLoC. Emite null cuando el campo es válido,
  /// o un String con el mensaje de error.
  final Stream<String?> errorStream;

  /// Callback invocado en cada cambio de texto.
  /// Conecta el TextField con el BLoC (bloc.changeName, etc.)
  final ValueChanged<String> onChanged;

  /// Icono opcional al inicio del campo.
  final IconData? prefixIcon;

  /// Tipo de teclado (numérico, texto, teléfono, etc.)
  final TextInputType? keyboardType;

  /// Valor inicial del campo (ej. nombre del usuario autenticado).
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p16),
      // StreamBuilder escucha el stream de errores y se reconstruye
      // cada vez que el BLoC emite un nuevo valor de validación.
      child: StreamBuilder<String?>(
        stream: errorStream,
        builder: (context, snapshot) {
          return TextFormField(
            initialValue: initialValue,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              // snapshot.data es el mensaje de error (o null si válido).
              // Solo se muestra si el stream ha emitido al menos un valor.
              errorText: snapshot.hasData ? snapshot.data : null,
            ),
            keyboardType: keyboardType,
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}
