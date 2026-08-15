import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
          for (final m in movies) {
            groups.putIfAbsent(m.seriesName ?? 'Standalone', () => []).add(m);
          }
          if (groups.isEmpty) return const Center(child: Text('no movies found.'));
          final w = MediaQuery.of(context).size.width;
          final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final e = groups.entries.elementAt(i);
              final group = MediaGroup(name: e.key ?? 'Standalone', category: MediaCategory.movies, items: e.value);
              return _buildMovieCard(context, group, cols);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
      ),
    );
  }

  Widget _buildMovieCard(BuildContext context, MediaGroup group, int cols) => GestureDetector(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieListScreen(groupName: group.name, movies: group.items)),
    ),
    child: Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: group.coverArtPath != null
              ? (kIsWeb
                  ? Image.network(group.coverArtPath!, fit: BoxFit.cover)
                  : Image.file(File(group.coverArtPath!), fit: BoxFit.cover))
              : _moviePlaceholder()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: Theme.of(context).cardColor,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${group.itemCount} movies', style: const TextStyle(color: Color(0xff3c9fdd), fontSize: 11)),
            ]),
          ),
        ],
      ),
    ),
  );
}

Widget _moviePlaceholder() => Container(color: const Color(0xff1a1a3a), child: const Center(child: Icon(Icons.movie, size: 44, color: Color(0xff3c9fdd))));

class MovieListScreen extends StatelessWidget {
  final String groupName;
  final List<MediaItem> movies;
  const MovieListScreen({super.key, required this.groupName, required this.movies});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75,
        ),
        itemCount: movies.length,
        itemBuilder: (_, i) {
          final m = movies[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m))),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: m.albumArtPath != null
                      ? (kIsWeb
                          ? Image.network(m.albumArtPath!, fit: BoxFit.cover)
                          : Image.file(File(m.albumArtPath!), fit: BoxFit.cover))
                      : _moviePlaceholder()),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: Theme.of(context).cardColor,
                    child: Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
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
