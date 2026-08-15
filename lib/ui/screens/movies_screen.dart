import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
<<<<<<< Updated upstream
=======
import 'package:watch/ui/widgets/media_card.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======

class _MoviesGrid extends ConsumerWidget {
  final Map<String?, List<MediaItem>> groups;
  const _MoviesGrid({required this.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortMode = ref.watch(sortModeProvider);
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    final mgroups = groups.entries.map((e) => MediaGroup(
      name: e.key ?? 'Standalone', category: MediaCategory.movies, items: e.value,
    )).toList();
    final sorted = sortGroups(mgroups, sortMode);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final group = sorted[i];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MovieListScreen(groupName: group.name, movies: group.items)),
          ),
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _MoviePlaceholder()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${group.itemCount} movies',
                          style: const TextStyle(color: Color(0xff3c9fdd), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoviePlaceholder extends StatelessWidget {
  const _MoviePlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xff1a1a3a),
    child: Center(child: Icon(Icons.movie, size: 44, color: Color(0xff3c9fdd))),
  );
}

class MovieListScreen extends StatelessWidget {
  final String groupName;
  final List<MediaItem> movies;
  const MovieListScreen({required this.groupName, required this.movies});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: movies.length,
        itemBuilder: (_, i) {
          final m = movies[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)),
            ),
            onLongPress: () => showMediaContextMenu(context, m, onPlay: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)));
              }),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Stack(
                    children: [
                      const _MoviePlaceholder(),
                      Positioned(left: 0, right: 0, bottom: 0, child: WatchedProgressBar(filePath: m.path)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: Theme.of(context).cardColor,
                    child: Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
>>>>>>> Stashed changes
