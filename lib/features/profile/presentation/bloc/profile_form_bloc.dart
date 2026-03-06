// ============================================================
// FILE: profile_form_bloc.dart
// PURPOSE: BLoC puro con RxDart para validación reactiva del
//          formulario de perfil de usuario.
//
// CONCEPTS TAUGHT:
//   - BLoC pattern (Business Logic Component): Separa la lógica
//     de validación de la UI. La UI envía eventos (change*) y
//     escucha streams de errores y estado.
//
//   - BehaviorSubject (de RxDart): Un StreamController especial que:
//     1. Siempre tiene un valor actual (.value)
//     2. Emite el último valor a nuevos listeners inmediatamente
//     Esto es perfecto para formularios: si un widget se reconstruye,
//     obtiene el último estado del campo sin esperar un nuevo evento.
//
//   - Rx.combineLatestList: Combina los últimos valores de múltiples
//     streams en uno solo. Se usa para calcular si TODO el formulario
//     es válido combinando todos los streams de validación.
//
//   - Validación reactiva: Cada campo tiene su propio stream de
//     errores. La UI usa StreamBuilder para mostrar errores en
//     tiempo real mientras el usuario escribe, sin necesidad de
//     llamar setState() ni usar un TextEditingController.
//
//   - Validación bajo demanda: _validationTriggered controla si los
//     errores de campos vacíos se muestran. Esto permite que el
//     usuario vea el formulario limpio al inicio, y al presionar
//     "Guardar" sin llenar, se muestren todos los errores.
//
// ARCHITECTURE:
//   Clase Dart pura (no depende de Flutter ni Riverpod).
//   Se instancia en initState() y se dispone en dispose().
// ============================================================

import 'dart:async';

import 'package:rxdart/rxdart.dart';

class ProfileFormBloc {
  // ── BehaviorSubjects (uno por campo) ──────────────────────────
  final _name = BehaviorSubject<String>.seeded('');
  final _age = BehaviorSubject<String>.seeded('');
  final _sex = BehaviorSubject<String>.seeded('');
  final _phone = BehaviorSubject<String>.seeded('');
  final _birthCity = BehaviorSubject<String>.seeded('');
  final _career = BehaviorSubject<String>.seeded('');
  final _semester = BehaviorSubject<String>.seeded('');
  final _birthDate = BehaviorSubject<DateTime?>.seeded(null);

  // ── Control de validación bajo demanda ────────────────────────
  // Cuando es false, los campos vacíos no muestran error (estado inicial).
  // Cuando es true (después de triggerValidation), los campos vacíos
  // muestran su error correspondiente.
  final _validationTriggered = BehaviorSubject<bool>.seeded(false);

  // ── Streams de validación (errores por campo) ─────────────────
  // Cada stream combina el valor del campo con _validationTriggered
  // para decidir si mostrar errores en campos vacíos.

  Stream<String?> get nameError => Rx.combineLatest2(
        _name.stream,
        _validationTriggered.stream,
        (String value, bool triggered) => _validateName(value, triggered),
      );

  Stream<String?> get ageError => Rx.combineLatest2(
        _age.stream,
        _validationTriggered.stream,
        (String value, bool triggered) => _validateAge(value, triggered),
      );

  Stream<String?> get sexError => Rx.combineLatest2(
        _sex.stream,
        _validationTriggered.stream,
        (String value, bool triggered) => _validateSex(value, triggered),
      );

  Stream<String?> get phoneError => Rx.combineLatest2(
        _phone.stream,
        _validationTriggered.stream,
        (String value, bool triggered) => _validatePhone(value, triggered),
      );

  Stream<String?> get birthCityError => Rx.combineLatest2(
        _birthCity.stream,
        _validationTriggered.stream,
        (String value, bool triggered) =>
            _validateBirthCity(value, triggered),
      );

  Stream<String?> get careerError => Rx.combineLatest2(
        _career.stream,
        _validationTriggered.stream,
        (String value, bool triggered) => _validateCareer(value, triggered),
      );

  Stream<String?> get semesterError => Rx.combineLatest2(
        _semester.stream,
        _validationTriggered.stream,
        (String value, bool triggered) =>
            _validateSemester(value, triggered),
      );

  Stream<String?> get birthDateError => Rx.combineLatest2(
        _birthDate.stream,
        _validationTriggered.stream,
        (DateTime? value, bool triggered) =>
            _validateBirthDate(value, triggered),
      );

  // ── Acceso al valor de fecha de nacimiento ────────────────────
  Stream<DateTime?> get birthDateStream => _birthDate.stream;
  DateTime? get birthDateValue => _birthDate.value;

  // ── isFormValid ───────────────────────────────────────────────
  Stream<bool> get isFormValid => Rx.combineLatestList<String?>([
        nameError,
        ageError,
        sexError,
        phoneError,
        birthCityError,
        careerError,
        semesterError,
        birthDateError,
      ]).map((errors) =>
          errors.every((error) => error == null) &&
          _name.value.isNotEmpty &&
          _age.value.isNotEmpty &&
          _sex.value.isNotEmpty &&
          _phone.value.isNotEmpty &&
          _birthCity.value.isNotEmpty &&
          _career.value.isNotEmpty &&
          _semester.value.isNotEmpty &&
          _birthDate.value != null);

  // ── Métodos change (alimentan los subjects) ───────────────────
  void changeName(String value) => _name.add(value);
  void changeAge(String value) => _age.add(value);
  void changeSex(String value) => _sex.add(value);
  void changePhone(String value) => _phone.add(value);
  void changeBirthCity(String value) => _birthCity.add(value);
  void changeCareer(String value) => _career.add(value);
  void changeSemester(String value) => _semester.add(value);
  void changeBirthDate(DateTime? value) => _birthDate.add(value);

  // ── Pre-carga de datos ────────────────────────────────────────
  void setInitialName(String value) => _name.add(value);

  // ── Validación bajo demanda ───────────────────────────────────
  // Al llamar triggerValidation(), re-emite todos los subjects para
  // forzar que los streams de error recalculen y muestren errores
  // en campos vacíos.
  void triggerValidation() {
    _validationTriggered.add(true);
    // Re-emitir todos los subjects para forzar recálculo
    _name.add(_name.value);
    _age.add(_age.value);
    _sex.add(_sex.value);
    _phone.add(_phone.value);
    _birthCity.add(_birthCity.value);
    _career.add(_career.value);
    _semester.add(_semester.value);
    _birthDate.add(_birthDate.value);
  }

  void resetValidation() {
    _validationTriggered.add(false);
  }

  // ── Submit ────────────────────────────────────────────────────
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

  // ── Validadores ───────────────────────────────────────────────
  // Cada validador recibe el valor del campo y si la validación fue
  // disparada. Si el campo está vacío y no se ha disparado, retorna
  // null (sin error). Si se disparó, muestra el error correspondiente.

  String? _validateName(String value, bool triggered) {
    if (value.isEmpty) return triggered ? 'El nombre es requerido' : null;
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateAge(String value, bool triggered) {
    if (value.isEmpty) return triggered ? 'La edad es requerida' : null;
    final age = int.tryParse(value);
    if (age == null) return 'Ingresa un número válido';
    if (age < 16 || age > 99) return 'La edad debe estar entre 16 y 99';
    return null;
  }

  String? _validateSex(String value, bool triggered) {
    if (value.isEmpty) return triggered ? 'Selecciona una opción' : null;
    return null;
  }

  String? _validatePhone(String value, bool triggered) {
    if (value.isEmpty) return triggered ? 'El teléfono es requerido' : null;
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Solo se permiten dígitos';
    if (value.length != 10) return 'El teléfono debe tener 10 dígitos';
    return null;
  }

  String? _validateBirthCity(String value, bool triggered) {
    if (value.isEmpty) return triggered ? 'La ciudad es requerida' : null;
    if (value.length < 3) {
      return 'La ciudad debe tener al menos 3 caracteres';
    }
    return null;
  }

  String? _validateCareer(String value, bool triggered) {
    if (value.isEmpty) return triggered ? 'Selecciona una carrera' : null;
    return null;
  }

  String? _validateSemester(String value, bool triggered) {
    if (value.isEmpty) {
      return triggered ? 'El semestre es requerido' : null;
    }
    final semester = int.tryParse(value);
    if (semester == null) return 'Ingresa un número válido';
    if (semester < 1 || semester > 12) {
      return 'El semestre debe estar entre 1 y 12';
    }
    return null;
  }

  String? _validateBirthDate(DateTime? value, bool triggered) {
    if (value == null) {
      return triggered ? 'Selecciona tu fecha de nacimiento' : null;
    }
    final now = DateTime.now();
    if (value.isAfter(now)) return 'La fecha debe ser en el pasado';
    final age = now.year - value.year -
        ((now.month > value.month ||
                (now.month == value.month && now.day >= value.day))
            ? 0
            : 1);
    if (age < 16) return 'Debes tener al menos 16 años';
    if (age > 99) return 'Edad máxima: 99 años';
    return null;
  }

  // ── Dispose ───────────────────────────────────────────────────
  void dispose() {
    _name.close();
    _age.close();
    _sex.close();
    _phone.close();
    _birthCity.close();
    _career.close();
    _semester.close();
    _birthDate.close();
    _validationTriggered.close();
  }
}
