import 'package:flutter/material.dart';

/// Overlay translúcido con spinner para bloquear la UI durante un
/// request en curso. Envuélvelo alrededor del contenido principal de
/// la pantalla y aliméntalo con `BlocBuilder<AuthBloc, AuthState>`
/// para que aparezca cuando `state.isLoading == true`.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
