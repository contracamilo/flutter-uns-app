import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:unisalle/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:unisalle/features/auth/presentation/widgets/loading_overlay.dart';
import 'package:unisalle/features/auth/presentation/widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
        final bloc = context.read<AuthBloc>();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'Volver',
              onPressed: () => context.goNamed(RouteNames.welcome),
            ),
          ),
          body: LoadingOverlay(
            isLoading: state.isLoading,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ───────────────────────────────────
                        Icon(
                          Icons.storefront_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bienvenido de nuevo',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inicia sesión en tu cuenta',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Form fields (validación reactiva via BLoC) ──
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          errorText: state.email.displayError,
                          onChanged: (v) =>
                              bloc.add(AuthLoginEmailChanged(v)),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          errorText: state.password.displayError,
                          onChanged: (v) =>
                              bloc.add(AuthLoginPasswordChanged(v)),
                          onSubmitted: (_) =>
                              bloc.add(const AuthLoginSubmitted()),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Función disponible próximamente'),
                                ),
                              );
                            },
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),

                        // ── Login button ─────────────────────────────
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: state.isLoading
                                ? null
                                : () =>
                                    bloc.add(const AuthLoginSubmitted()),
                            child: const Text('Iniciar Sesión'),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Divider ──────────────────────────────────
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o continuar con',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(153),
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Social buttons ───────────────────────────
                        SocialLoginButton(
                          label: 'Continuar con Google',
                          leading: const FaIcon(
                            FontAwesomeIcons.google,
                            size: 18,
                          ),
                          onPressed: state.isLoading
                              ? null
                              : () => bloc
                                  .add(const AuthGoogleSignInRequested()),
                        ),
                        const SizedBox(height: 12),
                        SocialLoginButton(
                          label: 'Continuar con GitHub',
                          leading: const FaIcon(
                            FontAwesomeIcons.github,
                            size: 18,
                          ),
                          onPressed: state.isLoading
                              ? null
                              : () => bloc
                                  .add(const AuthGithubSignInRequested()),
                        ),
                        const SizedBox(height: 32),

                        // ── Register link ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes cuenta? ',
                              style: theme.textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.goNamed(RouteNames.register),
                              child: Text(
                                'Regístrate',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }
}
