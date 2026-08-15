import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/services/settings_repo.dart';
import 'package:watch/services/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pornEnabled = ref.watch(pornToggleProvider);
    final themeAsync = ref.watch(themeModeProvider);
    final rootsAsync = ref.watch(mediaRootsProvider);
    final jellyUrl = ref.watch(jellyseerrApiUrlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: pornEnabled,
            onChanged: (v) => ref.read(pornToggleProvider.notifier).toggle(v),
            title: const Text('show adult content'),
          ),
          const Divider(),
          const Text('theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          themeAsync.when(
            data: (mode) => DropdownButtonFormField<String>(
              initialValue: mode,
              decoration: const InputDecoration(isDense: true),
              items: const ['system', 'light', 'dark']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) async {
                if (v != null) await (await SettingsRepo.getInstance()).setThemeMode(v);
                ref.invalidate(themeModeProvider);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('theme error: $e'),
          ),
          const Divider(),
          const Text('media roots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('set local paths (e.g. /storage/emulated/0/movies) or smb:// / nfs://',
              style: TextStyle(color: Color(0xff3c9fdd), fontSize: 12)),
          const SizedBox(height: 8),
          rootsAsync.when(
            data: (roots) => Column(
              children: roots.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(e.key.toUpperCase())),
                      Expanded(
                        flex: 4,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: kIsWeb
                            ? null
                            : () async {
                                final result = await FilePicker.platform.getDirectoryPath(
                                  dialogTitle: 'Choose media root for ${e.key}',
                                  initialDirectory: e.value,
                                );
                                if (result != null) {
                                  await (await SettingsRepo.getInstance()).setMediaRoot(e.key, result);
                                  ref.invalidate(mediaRootsProvider);
                                }
                              },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('error: $e'),
          ),
          const Divider(),
          const Text('jellyseerr', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('api url'),
            subtitle: Text(jellyUrl, style: const TextStyle(fontSize: 12)),
            trailing: kIsWeb ? const Chip(label: Text('proxied', style: TextStyle(fontSize: 11))) : null,
          ),
          if (jellyUrl.isEmpty || (!kIsWeb && !jellyUrl.startsWith('http')))
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Text('set JELLYSEERR_API_URL in .env or build with --dart-define.',
                  style: TextStyle(color: Color(0xff3c9fdd), fontSize: 11)),
            ),
          const Divider(),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('re-scan library'),
            onPressed: () => ref.invalidate(allMediaProvider),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.info_outline),
            label: const Text('override any path with .env variables'),
            onPressed: null,
          ),
        ],
      ),
    );
  }
}
