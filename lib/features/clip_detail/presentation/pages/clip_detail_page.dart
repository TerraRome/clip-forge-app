import 'package:flutter/material.dart';
import 'package:klip_mobile/core/di/injection.dart';
import 'package:klip_mobile/core/ui/app_primary_button.dart';
import 'package:klip_mobile/domain/entities/project.dart';
import 'package:klip_mobile/domain/repositories/project_repository.dart';
import 'package:klip_mobile/core/errors/exceptions.dart';

/// Page 5 — individual clip preview & download.
class ClipDetailPage extends StatefulWidget {
  const ClipDetailPage({
    super.key,
    required this.projectId,
    required this.clipIndex,
  });

  final String projectId;
  final int clipIndex;

  @override
  State<ClipDetailPage> createState() => _ClipDetailPageState();
}

class _ClipDetailPageState extends State<ClipDetailPage> {
  Project? _project;
  Clip? _clip;
  bool _loading = true;
  String? _error;
  final ProjectRepository _repo = sl();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => (_loading = true, _error = null));
    try {
      final project = await _repo.getProject(widget.projectId);
      final clip = project.clips[widget.clipIndex];
      setState(() {
        _project = project;
        _clip = clip;
        _loading = false;
      });
    } on AppException catch (e) {
      setState(() => (_error = e.message, _loading = false));
    } catch (e) {
      setState(() => (_error = 'Failed to load clip', _loading = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clip Detail')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final clip = _clip!;
    final project = _project!;
    final durationStr = _fmt(clip.endSec - clip.startSec);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video placeholder
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Clip info
          Text(
            'Clip ${clip.index}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(clip.startSec)} — ${_fmt(clip.endSec)} '
            '($durationStr)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'From: ${_truncate(project.url, 50)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),

          // Actions
          AppPrimaryButton(
            label: 'Download Clip',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Download started')));
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Results'),
          ),
        ],
      ),
    );
  }

  String _fmt(double sec) {
    final m = (sec / 60).floor();
    final s = (sec % 60).floor();
    return '${m}m ${s}s';
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}
