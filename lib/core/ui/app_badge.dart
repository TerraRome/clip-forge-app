import 'package:flutter/material.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../theme/tokens/typography_tokens.dart';
import '../theme/extensions/app_theme_extension.dart';

/// Small badge indicator for status labels and counts.
/// ponytail: add color variant support when badge types diversify.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = color ?? colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(SpacingTokens.radiusFull),
      ),
      child: Text(
        label,
        style: TypographyTokens.captionBold.copyWith(color: bg),
      ),
    );
  }
}
