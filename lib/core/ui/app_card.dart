import 'package:flutter/material.dart';
import '../theme/tokens/spacing_tokens.dart';

/// Standard card container for MVP screens.
/// Uses [ThemeData.cardTheme] for base styling.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SpacingTokens.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SpacingTokens.radiusMd),
        child: card,
      );
    }
    return card;
  }
}
