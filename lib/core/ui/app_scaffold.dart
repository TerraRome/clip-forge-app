import 'package:flutter/material.dart';
import '../theme/extensions/app_theme_extension.dart';

/// Standard screen scaffold for MVP screens.
/// Wraps [Scaffold] with safe-area, consistent background, and optional
/// bottom padding for gesture areas.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding = EdgeInsets.zero,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: appBar,
      body: SafeArea(
        child: Padding(padding: padding, child: body),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
