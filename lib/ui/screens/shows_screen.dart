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
<<<<<<< Updated upstream
=======

class _ShowsGrid extends ConsumerWidget {
  final Map<String, Map<String, List<MediaItem>>> shows;
  const _ShowsGrid({required this.shows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortMode = ref.watch(sortModeProvider);
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    final groups = shows.entries.map((e) {
      final allEps = e.value.values.expand((ep) => ep).toList();
      return MediaGroup(name: e.key, category: MediaCategory.shows, items: allEps);
    }).toList();
    final sorted = sortGroups(groups, sortMode);
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
            MaterialPageRoute(builder: (_) => SeasonGrid(showName: group.name, seasons: shows[group.name]!)),
          ),
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _ShowPlaceholder()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${group.itemCount} episodes',
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

class _ShowPlaceholder extends StatelessWidget {
  const _ShowPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xff1a1a3a),
    child: Center(child: Icon(Icons.tv, size: 44, color: Color(0xff3c9fdd))),
  );
}

class SeasonGrid extends StatelessWidget {
  final String showName;
  final Map<String, List<MediaItem>> seasons;
  const SeasonGrid({required this.showName, required this.seasons});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    final entries = seasons.entries.toList();
    return Scaffold(
      appBar: AppBar(title: Text(showName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final e = entries[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EpisodeGrid(seasonName: e.key, episodes: e.value)),
            ),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: _ShowPlaceholder()),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: Theme.of(context).cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${e.value.length} episodes',
                            style: const TextStyle(color: Color(0xff3c9fdd), fontSize: 11)),
                      ],
                    ),
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

class EpisodeGrid extends StatelessWidget {
  final String seasonName;
  final List<MediaItem> episodes;
  const EpisodeGrid({required this.seasonName, required this.episodes});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return Scaffold(
      appBar: AppBar(title: Text(seasonName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: episodes.length,
        itemBuilder: (_, i) {
          final ep = episodes[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: ep)),
            ),
            onLongPress: () => showMediaContextMenu(context, ep, onPlay: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: ep)));
              }),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Stack(
                    children: [
                      const _ShowPlaceholder(),
                      Positioned(left: 0, right: 0, bottom: 0, child: WatchedProgressBar(filePath: ep.path)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: Theme.of(context).cardColor,
                    child: Text(ep.title, maxLines: 2, overflow: TextOverflow.ellipsis,
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
