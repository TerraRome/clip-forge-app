import 'package:flutter/material.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../theme/extensions/app_theme_extension.dart';

/// Primary action button. Full-width by default (MVP needs).
/// Uses [ThemeData.elevatedButtonTheme] for base styling.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onPrimary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: SpacingTokens.xs),
                ],
                Text(label),
              ],
            ),
    );
  }
}
