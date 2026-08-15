import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';

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

class _ShowPlaceholder extends StatelessWidget {
  const _ShowPlaceholder();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff0a0a0a),
    child: Center(child: Icon(Icons.tv, size: 44, color: Color(0xff3c9fdd))),
  );
}

class SeasonGrid extends StatelessWidget {
  final String showName;
  final Map<String, List<MediaItem>> seasons;
  const SeasonGrid({super.key, required this.showName, required this.seasons});

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
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.8,
        ),
        itemCount: entries.length,
        itemBuilder: (_, i) {
          final e = entries[i];
          final placeholder = const _ShowPlaceholder();
          final firstThumb = e.value.firstWhere((m) => m.thumbnailPath != null, orElse: () => e.value.first).thumbnailPath;
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EpisodeGrid(seasonName: e.key, episodes: e.value)),
            ),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Stack(
                    children: [
                      firstThumb != null
                          ? (kIsWeb
                              ? Image.network(firstThumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
                              : Image.file(File(firstThumb), fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder))
                          : placeholder,
                      Positioned(left: 0, right: 0, bottom: 0, child: WatchedProgressBar(filePath: e.value.first.path)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: Theme.of(context).cardColor,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${e.value.length} episodes', style: const TextStyle(color: Color(0xff3c9fdd), fontSize: 11)),
                    ]),
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
  const EpisodeGrid({super.key, required this.seasonName, required this.episodes});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return Scaffold(
      appBar: AppBar(title: Text(seasonName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75,
        ),
        itemCount: episodes.length,
        itemBuilder: (_, i) {
          final ep = episodes[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: ep))),
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
                    child: Text(ep.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
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
