import 'package:flutter/material.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../theme/tokens/typography_tokens.dart';
import '../theme/extensions/app_theme_extension.dart';
import 'app_card.dart';

/// Card that displays a video thumbnail placeholder with metadata.
/// Used in results screen to show generated clips.
class AppVideoCard extends StatelessWidget {
  const AppVideoCard({
    super.key,
    required this.label,
    this.duration,
    this.onTap,
    this.onDownload,
  });

  final String label;
  final String? duration;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail placeholder
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(SpacingTokens.radiusMd),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
          // Metadata row
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TypographyTokens.captionBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (duration != null)
                  Padding(
                    padding: const EdgeInsets.only(left: SpacingTokens.xs),
                    child: Text(
                      duration!,
                      style: TypographyTokens.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                if (onDownload != null) ...[
                  const SizedBox(width: SpacingTokens.xs),
                  IconButton(
                    icon: const Icon(Icons.download, size: 18),
                    onPressed: onDownload,
                    color: colors.textSecondary,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Download clip',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
