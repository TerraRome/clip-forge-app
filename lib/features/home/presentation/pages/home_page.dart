import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI YouTube Clipper')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push(AppRoute.newProject),
          child: const Text('New Clip'),
        ),
      ),
    );
  }
}
