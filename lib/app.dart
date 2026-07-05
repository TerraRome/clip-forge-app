import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';

/// Root application widget.
class KlipApp extends StatelessWidget {
  const KlipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI YouTube Clipper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
