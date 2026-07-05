import 'package:flutter/material.dart';
import 'package:klip_mobile/core/ui/app_primary_button.dart';

/// Page 6 — Settings (MVP: server URL config, theme toggle stubs).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController(text: 'http://localhost:8000');

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server URL
          Text(
            'API Server URL',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              hintText: 'http://localhost:8000',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Placeholder toggles
          const SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: const Text('(future)'),
            value: false,
            onChanged: null,
          ),
          const Divider(),
          const SwitchListTile(
            title: Text('Auto-download clips'),
            subtitle: const Text('(future)'),
            value: false,
            onChanged: null,
          ),
          const SizedBox(height: 32),

          // Save
          AppPrimaryButton(
            label: 'Save',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved (local only)')),
              );
            },
          ),
          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              'AI YouTube Clipper v0.1.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
