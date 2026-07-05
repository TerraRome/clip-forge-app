import 'package:flutter/material.dart';

class ClipDetailPage extends StatelessWidget {
  const ClipDetailPage({
    super.key,
    required this.projectId,
    required this.clipIndex,
  });

  final String projectId;
  final int clipIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clip Detail')),
      body: Center(child: Text('Project: $projectId, Clip: $clipIndex')),
    );
  }
}
