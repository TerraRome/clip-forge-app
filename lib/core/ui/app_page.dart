import 'package:flutter/material.dart';
import '../theme/extensions/app_theme_extension.dart';

/// Standard page layout with safe area and consistent padding.
/// Wraps [SafeArea] + optional scroll.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.padding = true,
    this.scrollable = false,
  });

  final Widget child;
  final bool padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = SafeArea(
      child: padding
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: child,
            )
          : child,
    );

    return Container(
      color: colors.background,
      child: scrollable ? SingleChildScrollView(child: body) : body,
    );
  }
}
