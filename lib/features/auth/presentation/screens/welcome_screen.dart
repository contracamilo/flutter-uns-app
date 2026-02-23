import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';

/// Pantalla de bienvenida / splash de la aplicación.
///
/// Es la primera pantalla que ve el usuario. Muestra el branding de
/// la app y ofrece dos acciones principales: iniciar sesión o registrarse.
///
/// DISEÑO:
/// - Fondo superior con gradiente del color primario (branding)
/// - Panel inferior en color superficie con los botones de acción
/// - Separación visual mediante bordes redondeados en la parte superior
///   del panel inferior (patrón común en apps modernas)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Container(
        // Gradient background using the app's primary color
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              cs.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Branding section ──────────────────────────────────
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App icon with frosted-glass style background
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withAlpha(40),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 56,
                          color: cs.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'UniSalle',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu tienda universitaria',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onPrimary.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Actions panel ─────────────────────────────────────
              // Rounded top corners create a "card rising from below" effect
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Comienza ahora',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inicia sesión o crea tu cuenta para continuar.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withAlpha(153),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary CTA: Login
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => context.goNamed(RouteNames.login),
                        child: const Text('Iniciar Sesión'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary CTA: Register
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.goNamed(RouteNames.register),
                        child: const Text('Crear cuenta'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
