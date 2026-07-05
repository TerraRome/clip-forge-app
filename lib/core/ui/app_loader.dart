import 'package:flutter/material.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../theme/tokens/typography_tokens.dart';
import '../theme/extensions/app_theme_extension.dart';

/// Full-screen loading overlay for async operations.
/// Covers entire screen with semi-transparent backdrop.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.overlay,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            if (message != null) ...[
              const SizedBox(height: SpacingTokens.md),
              Text(
                message!,
                style: TypographyTokens.body.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
