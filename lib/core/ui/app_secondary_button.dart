import 'package:flutter/material.dart';
import '../theme/tokens/spacing_tokens.dart';

/// Secondary action button. Full-width by default.
/// Uses [ThemeData.outlinedButtonTheme] for base styling.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: SpacingTokens.xs)],
          Text(label),
        ],
      ),
    );
  }
}
