import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/services/providers.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMediaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('movies')),
      body: items.when(
        data: (all) {
          final movies = all.where((m) => m.category == MediaCategory.movies).toList();
          final Map<String?, List<MediaItem>> groups = {};
          for (final m in movies) { groups.putIfAbsent(m.seriesName ?? 'Standalone', () => []).add(m); }
          if (groups.isEmpty) return const Center(child: Text('no movies found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final e = groups.entries.elementAt(i);
              return ExpansionTile(
                leading: const Icon(Icons.movie, size: 36),
                title: Text(e.key ?? 'Standalone'),
                subtitle: Text('${e.value.length} movies'),
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
