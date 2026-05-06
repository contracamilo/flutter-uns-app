import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unisalle/core/auth/token_storage.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/core/extensions/build_context_extensions.dart';
import 'package:unisalle/features/auth/domain/entities/user.dart';
import 'package:unisalle/features/auth/presentation/bloc/auth_bloc.dart';

/// Cabecera de cuenta para `ProfileScreen`.
///
/// Muestra avatar, nombre, email y roles del usuario autenticado.
/// Permite cambiar la foto disparando `AuthProfileImageUpdateRequested`
/// en el `AuthBloc`; el resultado (éxito/error) llega vía `BlocListener`.
///
/// El botón "Cambiar foto" solo aparece para usuarios autenticados con
/// el backend (i.e. con JWT en `TokenStorage`). Los usuarios OAuth de
/// Google/GitHub no tienen registro en el backend y verán un mensaje
/// informativo en su lugar.
class AccountHeader extends ConsumerStatefulWidget {
  const AccountHeader({super.key, required this.user});

  final User user;

  @override
  ConsumerState<AccountHeader> createState() => _AccountHeaderState();
}

class _AccountHeaderState extends ConsumerState<AccountHeader> {
  final _picker = ImagePicker();
  bool _uploading = false;
  bool _hasBackendToken = false;
  String? _previousPhotoUrl;

  @override
  void initState() {
    super.initState();
    _previousPhotoUrl = widget.user.photoUrl;
    _checkBackendToken();
  }

  Future<void> _checkBackendToken() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (!mounted) return;
    setState(() => _hasBackendToken = token != null && token.isNotEmpty);
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _uploading = true);
    context
        .read<AuthBloc>()
        .add(AuthProfileImageUpdateRequested(File(picked.path)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final user = widget.user;

    return BlocListener<AuthBloc, AuthState>(
      // Refleja errores de subida y éxitos via comparación del photoUrl.
      listener: (context, state) {
        if (!_uploading) return;
        if (state.errorMessage != null) {
          setState(() => _uploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo subir la imagen: ${state.errorMessage}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (state.user?.photoUrl != _previousPhotoUrl) {
          _previousPhotoUrl = state.user?.photoUrl;
          setState(() => _uploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSizes.p16),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _Avatar(photoUrl: user.photoUrl, name: user.name),
                  if (_hasBackendToken)
                    Material(
                      color: cs.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploading ? null : _pickAndUpload,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.p8),
                          child: _uploading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: cs.onPrimary,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
              Text(
                user.name,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.email,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (user.roles.isNotEmpty) ...[
                const SizedBox(height: AppSizes.p12),
                Wrap(
                  spacing: AppSizes.p8,
                  runSpacing: AppSizes.p4,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final role in user.roles)
                      Chip(
                        label: Text(role),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              if (!_hasBackendToken) ...[
                const SizedBox(height: AppSizes.p12),
                Text(
                  'Tu sesión es de Google/GitHub. Cambia tu foto desde tu cuenta del proveedor.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final initials = _initials(name);

    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: cs.primaryContainer,
        child: Text(
          initials,
          style: context.textTheme.headlineSmall?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 44,
      backgroundColor: cs.primaryContainer,
      foregroundImage: NetworkImage(photoUrl!),
      child: Text(
        initials,
        style: context.textTheme.headlineSmall?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
