// ============================================================
// FILE: profile_screen.dart
// PURPOSE: Pantalla de perfil con dos modos:
//   - Vista (read-only): muestra datos guardados en ListTiles
//   - Edición: formulario con validaciones reactivas via BLoC + RxDart
//
// CONCEPTS TAUGHT:
//   - ConsumerStatefulWidget: Combina StatefulWidget (para ciclo de
//     vida del BLoC) con Consumer (para acceder a ref y providers).
//
//   - Estado global vs local: Los datos guardados del perfil viven
//     en profileProvider (Riverpod) y sobreviven la navegación.
//     El BLoC de validación es local al widget y se recrea cada vez
//     que se abre la pantalla, pre-cargándose del provider.
//
//   - Modo vista/edición: Un solo widget alterna entre mostrar datos
//     y permitir editarlos. El estado _isEditing controla el modo.
//
//   - PopScope: Intercepta el botón back del sistema para preguntar
//     si el usuario quiere salir sin guardar cambios en modo edición.
//
//   - Date picker: Usa showDatePicker nativo de Material para
//     seleccionar la fecha de nacimiento.
//
// ARCHITECTURE DECISION:
//   Esta pantalla mezcla intencionalmente Riverpod (para auth y
//   persistencia del perfil) con BLoC puro (para el formulario).
//   Esto demuestra que ambos patrones pueden coexistir.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/core/extensions/build_context_extensions.dart';
import 'package:unisalle/features/auth/providers/auth_provider.dart';
import 'package:unisalle/features/profile/presentation/bloc/profile_form_bloc.dart';
import 'package:unisalle/features/profile/presentation/widgets/profile_text_field.dart';
import 'package:unisalle/features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ProfileFormBloc _bloc;
  bool _isEditing = false;

  // Opciones predefinidas para los dropdowns.
  static const _sexOptions = ['Masculino', 'Femenino', 'Otro'];
  static const _careerOptions = [
    'Ingeniería de Sistemas',
    'Ingeniería Civil',
    'Ingeniería Industrial',
    'Administración de Empresas',
    'Contaduría Pública',
    'Medicina Veterinaria',
    'Trabajo Social',
    'Arquitectura',
  ];

  @override
  void initState() {
    super.initState();
    _bloc = ProfileFormBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cargar el BLoC con datos guardados o nombre del usuario auth.
    _preloadBloc();
  }

  /// Pre-carga el BLoC con los datos del perfil guardado en el provider,
  /// o con el nombre del usuario autenticado si no hay perfil guardado.
  void _preloadBloc() {
    final saved = ref.read(profileProvider);
    if (saved != null) {
      _bloc.changeName(saved['nombre'] as String? ?? '');
      _bloc.changeAge(saved['edad'] as String? ?? '');
      _bloc.changeSex(saved['sexo'] as String? ?? '');
      _bloc.changePhone(saved['telefono'] as String? ?? '');
      _bloc.changeBirthCity(saved['ciudadNacimiento'] as String? ?? '');
      _bloc.changeCareer(saved['carrera'] as String? ?? '');
      _bloc.changeSemester(saved['semestre'] as String? ?? '');
      final birthDateStr = saved['fechaNacimiento'] as String?;
      if (birthDateStr != null) {
        _bloc.changeBirthDate(DateTime.tryParse(birthDateStr));
      }
    } else {
      final user = ref.read(authProvider).valueOrNull;
      if (user != null && user.name.isNotEmpty) {
        _bloc.setInitialName(user.name);
      }
    }
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final data = _bloc.submitForm();
    // Guardar en el provider global para que persista entre navegaciones.
    ref.read(profileProvider.notifier).save(data);
    setState(() => _isEditing = false);
    _bloc.resetValidation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perfil guardado: ${data['nombre']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text(
          '¿Estás seguro de que deseas salir? Los cambios no guardados se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'No especificado';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'No especificado';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bloc.birthDateValue ?? DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
    );
    if (picked != null) {
      _bloc.changeBirthDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Leer el perfil del provider para el modo vista.
    final savedProfile = ref.watch(profileProvider);

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _showUnsavedChangesDialog();
        if (leave && mounted) {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Editar Perfil' : 'Mi Perfil'),
          actions: [
            if (_isEditing)
              TextButton(
                onPressed: () {
                  setState(() => _isEditing = false);
                  _bloc.resetValidation();
                },
                child: const Text('Cancelar'),
              )
            else
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar perfil',
                onPressed: () => setState(() => _isEditing = true),
              ),
          ],
        ),
        body: _isEditing
            ? _buildEditForm()
            : _buildViewMode(savedProfile),
      ),
    );
  }

  // ── Modo Vista (read-only) ──────────────────────────────────
  Widget _buildViewMode(Map<String, dynamic>? savedProfile) {
    if (savedProfile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 96,
                color: context.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              Text(
                'Perfil vacío',
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.p8),
              Text(
                'Toca el icono de editar para completar tu perfil',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.p8),
          Icon(
            Icons.account_circle,
            size: 80,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            savedProfile['nombre'] as String? ?? '',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            savedProfile['carrera'] as String? ?? '',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          Card(
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person_outline,
                  'Nombre',
                  savedProfile['nombre'] as String?,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.cake_outlined,
                  'Edad',
                  savedProfile['edad'] as String?,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.calendar_month_outlined,
                  'Fecha de nacimiento',
                  _formatDate(
                    savedProfile['fechaNacimiento'] as String?,
                  ),
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.wc_outlined,
                  'Sexo',
                  savedProfile['sexo'] as String?,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Teléfono',
                  savedProfile['telefono'] as String?,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.location_city_outlined,
                  'Ciudad de nacimiento',
                  savedProfile['ciudadNacimiento'] as String?,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.school_outlined,
                  'Carrera',
                  savedProfile['carrera'] as String?,
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Semestre',
                  savedProfile['semestre'] as String?,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: context.colorScheme.primary),
      title: Text(label, style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      )),
      subtitle: Text(
        (value != null && value.isNotEmpty) ? value : 'No especificado',
        style: context.textTheme.bodyLarge,
      ),
    );
  }

  // Retorna null si el valor del bloc está vacío (no está en los items).
  String? _sexInitialValue() {
    final v = _bloc.submitForm()['sexo'] as String?;
    return (v != null && v.isNotEmpty) ? v : null;
  }

  String? _careerInitialValue() {
    final v = _bloc.submitForm()['carrera'] as String?;
    return (v != null && v.isNotEmpty) ? v : null;
  }

  // ── Modo Edición (formulario) ─────────────────────────────────
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.account_circle,
            size: 80,
            color: context.colorScheme.primary,
          ),
          const SizedBox(height: AppSizes.p24),

          ProfileTextField(
            label: 'Nombre',
            prefixIcon: Icons.person_outline,
            errorStream: _bloc.nameError,
            onChanged: _bloc.changeName,
            initialValue: _bloc.submitForm()['nombre'] as String?,
          ),
          ProfileTextField(
            label: 'Edad',
            prefixIcon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            errorStream: _bloc.ageError,
            onChanged: _bloc.changeAge,
            initialValue: _bloc.submitForm()['edad'] as String?,
          ),

          // ── Date picker: Fecha de nacimiento ──────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p16),
            child: StreamBuilder<String?>(
              stream: _bloc.birthDateError,
              builder: (context, errorSnapshot) {
                return StreamBuilder<DateTime?>(
                  stream: _bloc.birthDateStream,
                  builder: (context, dateSnapshot) {
                    final date = dateSnapshot.data;
                    final formattedDate = date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : null;
                    return InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha de nacimiento',
                          prefixIcon:
                              const Icon(Icons.calendar_month_outlined),
                          suffixIcon:
                              const Icon(Icons.arrow_drop_down),
                          errorText: errorSnapshot.hasData
                              ? errorSnapshot.data
                              : null,
                        ),
                        child: Text(
                          formattedDate ?? 'Seleccionar fecha',
                          style: formattedDate != null
                              ? context.textTheme.bodyLarge
                              : context.textTheme.bodyLarge?.copyWith(
                                  color:
                                      context.colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Dropdown: Sexo ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p16),
            child: StreamBuilder<String?>(
              stream: _bloc.sexError,
              builder: (context, snapshot) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sexo',
                    prefixIcon: const Icon(Icons.wc_outlined),
                    errorText: snapshot.hasData ? snapshot.data : null,
                  ),
                  initialValue: _sexInitialValue(),
                  items: _sexOptions
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _bloc.changeSex(value);
                  },
                );
              },
            ),
          ),

          ProfileTextField(
            label: 'Teléfono',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            errorStream: _bloc.phoneError,
            onChanged: _bloc.changePhone,
            initialValue: _bloc.submitForm()['telefono'] as String?,
          ),
          ProfileTextField(
            label: 'Ciudad de nacimiento',
            prefixIcon: Icons.location_city_outlined,
            errorStream: _bloc.birthCityError,
            onChanged: _bloc.changeBirthCity,
            initialValue:
                _bloc.submitForm()['ciudadNacimiento'] as String?,
          ),

          // ── Dropdown: Carrera ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p16),
            child: StreamBuilder<String?>(
              stream: _bloc.careerError,
              builder: (context, snapshot) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Carrera',
                    prefixIcon: const Icon(Icons.school_outlined),
                    errorText: snapshot.hasData ? snapshot.data : null,
                  ),
                  initialValue: _careerInitialValue(),
                  items: _careerOptions
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _bloc.changeCareer(value);
                  },
                );
              },
            ),
          ),

          ProfileTextField(
            label: 'Semestre',
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            errorStream: _bloc.semesterError,
            onChanged: _bloc.changeSemester,
            initialValue: _bloc.submitForm()['semestre'] as String?,
          ),

          const SizedBox(height: AppSizes.p24),

          StreamBuilder<bool>(
            stream: _bloc.isFormValid,
            initialData: false,
            builder: (context, snapshot) {
              final isValid = snapshot.data ?? false;
              return FilledButton.icon(
                onPressed: () {
                  if (isValid) {
                    _onSubmit();
                  } else {
                    _bloc.triggerValidation();
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.p48),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
