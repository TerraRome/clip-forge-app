import 'package:flutter/material.dart';

class ProcessingPage extends StatelessWidget {
  const ProcessingPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: Center(child: Text('Processing project: $projectId')),
    );
  }
}
