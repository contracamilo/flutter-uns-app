import 'package:flutter/material.dart';

/// Reusable social / OAuth login button with a leading icon widget.
///
/// Accepts any [Widget] as [leading] so it works with both
/// Material [Icon]s and third-party icons like [FaIcon] (Font Awesome).
///
/// Example:
/// ```dart
/// SocialLoginButton(
///   label: 'Continuar con Google',
///   leading: FaIcon(FontAwesomeIcons.google, size: 18),
///   onPressed: _handleGoogleLogin,
/// )
/// ```
class SocialLoginButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.leading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}
