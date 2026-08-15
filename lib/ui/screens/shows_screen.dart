import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/services/providers.dart';

class ShowsScreen extends ConsumerWidget {
  const ShowsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMediaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('shows')),
      body: items.when(
        data: (all) {
          final shows = all.where((m) => m.category == MediaCategory.shows).toList();
          final Map<String, Map<String, List<MediaItem>>> grid = {};
          for (final m in shows) {
            final s = m.seriesName ?? 'Unknown';
            final ss = m.season ?? 'Unknown';
            grid.putIfAbsent(s, () => {});
            grid[s]!.putIfAbsent(ss, () => []).add(m);
          }
          if (grid.isEmpty) return const Center(child: Text('no shows found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: grid.length,
            itemBuilder: (_, i) {
              final entry = grid.entries.elementAt(i);
              final allEps = entry.value.values.expand((e) => e).toList();
              return ExpansionTile(
                leading: const Icon(Icons.tv, size: 36),
                title: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${allEps.length} episodes'),
                children: entry.value.entries.map((s) => ExpansionTile(
                  title: Text(s.key),
                  children: s.value.map((ep) => ListTile(
                    title: Text(ep.title),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: ep))),
                  )).toList(),
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
