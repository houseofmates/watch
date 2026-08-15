import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/services/providers.dart';

class PornScreen extends ConsumerWidget {
  const PornScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(pornToggleProvider);
    if (!enabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('adult content')),
        body: const Center(child: Text('this category is hidden.\nenable "show adult content" in settings.')),
      );
    }
    final items = ref.watch(filteredMediaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('adult content')),
      body: items.when(
        data: (all) {
          final porn = all.where((m) => m.category == MediaCategory.porn).toList();
          final Map<String, List<MediaItem>> byStudio = {};
          for (final m in porn) byStudio.putIfAbsent(m.seriesName ?? 'unknown', () => []).add(m);
          if (byStudio.isEmpty) return const Center(child: Text('no adult content found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: byStudio.length,
            itemBuilder: (_, i) {
              final e = byStudio.entries.elementAt(i);
              return ExpansionTile(
                leading: const Icon(Icons.lock, size: 36),
                title: Text(e.key),
                subtitle: Text('${e.value.length} videos'),
                children: e.value.map((m) => ListTile(
                  title: Text(m.title),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m))),
                )).toList(),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
      ),
    );
  }
}
