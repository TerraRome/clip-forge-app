import 'package:flutter/material.dart';

class NewProjectPage extends StatelessWidget {
  const NewProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Clip')),
      body: const Center(child: Text('Paste YouTube URL & select clips')),
    );
  }
}
