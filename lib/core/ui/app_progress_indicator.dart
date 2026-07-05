import 'package:flutter/material.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../theme/tokens/typography_tokens.dart';
import '../theme/extensions/app_theme_extension.dart';

/// Linear progress indicator with optional label.
/// Used in processing screen to show clip generation progress.
class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({super.key, required this.progress, this.label});

  /// Value 0.0–1.0.
  final double progress;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.surfaceVariant,
            color: colors.primary,
            minHeight: 6,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            label!,
            style: TypographyTokens.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
