import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/widgets/media_card.dart';

/// /movies — loose gallery of individual movie cards (no folder grouping).
/// Each card shows the movie poster (TMDb) or video frame.
/// Tap a card → play the movie directly.
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
          if (movies.isEmpty) return const Center(child: Text('no movies found.'));
          final w = MediaQuery.of(context).size.width;
          final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.65,
            ),
            itemCount: movies.length,
            itemBuilder: (_, i) {
              final m = movies[i];
              final group = MediaGroup(
                name: m.title,
                category: MediaCategory.movies,
                coverArtPath: m.thumbnailPath,
                items: [m],
              );
              return MediaCard(
                group: group,
                aspectRatio: 0.75,
                width: 140,
                subtitle: _movieSubtitle(m),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
      ),
    );
  }

  String _movieSubtitle(MediaItem m) {
    final parts = <String>[];
    if (m.durationSeconds != null) {
      final total = m.durationSeconds!;
      final h = total ~/ 3600;
      final min = (total % 3600) ~/ 60;
      if (h > 0) {
        parts.add('${h}h ${min}m');
      } else {
        parts.add('${min}m');
      }
    }
    if (m.extension.isNotEmpty) {
      parts.add(m.extension.substring(1));
    }
    return parts.join(' · ');
  }
}
