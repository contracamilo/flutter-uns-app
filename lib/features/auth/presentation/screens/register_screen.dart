import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/config/auth_config.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:unisalle/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:unisalle/features/auth/presentation/widgets/loading_overlay.dart';
import 'package:unisalle/features/auth/presentation/widgets/social_login_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
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
                          Icons.person_add_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Crear cuenta',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Regístrate para comenzar a comprar',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Social buttons ───────────────────────────
                        SocialLoginButton(
                          label: 'Registrarse con Google',
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
                          label: 'Registrarse con GitHub',
                          leading: const FaIcon(
                            FontAwesomeIcons.github,
                            size: 18,
                          ),
                          onPressed:
                              state.isLoading || !GithubAuthConfig.isConfigured
                                  ? null
                                  : () => bloc
                                      .add(const AuthGithubSignInRequested()),
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
                                'o regístrate con email',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(153),
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Form fields ──────────────────────────────
                        AuthTextField(
                          controller: _nameController,
                          label: 'Nombre completo',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          errorText: state.name.displayError,
                          onChanged: (v) =>
                              bloc.add(AuthRegisterNameChanged(v)),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          errorText: state.email.displayError,
                          onChanged: (v) =>
                              bloc.add(AuthRegisterEmailChanged(v)),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          errorText: state.password.displayError,
                          onChanged: (v) =>
                              bloc.add(AuthRegisterPasswordChanged(v)),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          errorText: state.confirmPassword.displayError,
                          onChanged: (v) => bloc
                              .add(AuthRegisterConfirmPasswordChanged(v)),
                          onSubmitted: (_) =>
                              bloc.add(const AuthRegisterSubmitted()),
                        ),
                        const SizedBox(height: 24),

                        // ── Register button ──────────────────────────
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: state.isLoading
                                ? null
                                : () => bloc
                                    .add(const AuthRegisterSubmitted()),
                            child: const Text('Crear cuenta'),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Login link ───────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes cuenta? ',
                              style: theme.textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  context.goNamed(RouteNames.login),
                              child: Text(
                                'Inicia sesión',
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
    );
  }
}
