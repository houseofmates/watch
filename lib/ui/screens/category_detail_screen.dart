import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/widgets/thumbnail_image.dart';
import 'package:watch/ui/widgets/media_card.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';

/// Category detail page reached via URL slug:
///   `/shows/:slug`         — season cards as a gallery; tap → episode grid
///   `/movies/:slug`        — loose movie cards in a gallery
///   `/porn/:slug`          — loose video cards in a gallery (horizontal)
///
/// Each thumbnail is right-clickable (web/desktop) / long-pressable (mobile)
/// to swap the image via the ThumbnailImage context menu.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String category;
  final String slug;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.slug,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(allMediaProvider);
    final title = switch (widget.category) {
      MediaCategory.shows => 'shows',
      MediaCategory.movies => 'movies',
      MediaCategory.porn => 'adult',
      _ => widget.category,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: itemsAsync.when(
        data: (items) {
          final catItems = items.where((m) => m.category == widget.category).toList();
          if (catItems.isEmpty) {
            return const Center(child: Text('nothing here yet.'));
          }

          // Reconstruct groups and find the one matching our slug
          final groups = groupMedia(catItems, widget.category);
          MediaGroup? matchingGroup;
          for (final g in groups) {
            if (slugify(g.name) == widget.slug) {
              matchingGroup = g;
              break;
            }
          }

          if (matchingGroup == null || matchingGroup.items.isEmpty) {
            return const Center(child: Text('no items found for this slug.'));
          }

          if (widget.category == MediaCategory.shows) {
            return _SeasonGallery(
              showName: matchingGroup.name,
              allItems: matchingGroup.items,
            );
          }

          // Movies and porn: loose item gallery
          return _ItemGallery(
            category: widget.category,
            items: matchingGroup.items,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
      ),
    );
  }
}

/// Shows seasons as gallery cards (MediaCard-style). Tap a season → episode grid.
class _SeasonGallery extends StatelessWidget {
  final String showName;
  final List<MediaItem> allItems;

  const _SeasonGallery({required this.showName, required this.allItems});

  @override
  Widget build(BuildContext context) {
    // Group items by season
    final seasons = <String, List<MediaItem>>{};
    for (final item in allItems) {
      final ssn = item.season ?? 'Unknown';
      seasons.putIfAbsent(ssn, () => []).add(item);
    }

    if (seasons.isEmpty) {
      return const Center(child: Text('no seasons found.'));
    }

    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: seasons.length,
      itemBuilder: (_, i) {
        final entry = seasons.entries.elementAt(i);
        final epList = entry.value;
        final firstEp = epList.firstWhere(
            (m) => m.type == MediaType.video, orElse: () => epList.first);
        final group = MediaGroup(
          name: entry.key,
          category: MediaCategory.shows,
          coverArtPath: firstEp.thumbnailPath,
          items: epList,
        );
        return MediaCard(
          group: group,
          aspectRatio: 0.8,
          width: 130,
          subtitle: '${epList.length} episodes',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _EpisodeGrid(
                showName: showName,
                seasonName: entry.key,
                episodes: epList,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Grid of individual media items (movies or porn videos). Tap → play.
class _ItemGallery extends StatelessWidget {
  final String category;
  final List<MediaItem> items;

  const _ItemGallery({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    final isPorn = category == MediaCategory.porn;
    final aspectRatio = isPorn ? 1.5 : 0.8;
    final gridRatio = isPorn ? 1.3 : 0.7;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: gridRatio,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        final group = MediaGroup(
          name: m.title,
          category: category,
          coverArtPath: m.thumbnailPath,
          items: [m],
        );
        return MediaCard(
          group: group,
          aspectRatio: aspectRatio,
          width: 140,
          subtitle: _subtitle(m, isPorn),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)),
          ),
        );
      },
    );
  }

  String _subtitle(MediaItem m, bool isPorn) {
    if (isPorn && m.durationSeconds != null) {
      final total = m.durationSeconds!;
      final h = total ~/ 3600;
      final min = (total % 3600) ~/ 60;
      return h > 0 ? '${h}h ${min}m' : '${min}m';
    }
    if (m.durationSeconds != null) {
      final total = m.durationSeconds!;
      final h = total ~/ 3600;
      final min = (total % 3600) ~/ 60;
      return h > 0 ? '${h}h ${min}m' : '${min}m';
    }
    return m.extension;
  }
}

/// Full-screen episode grid — tapped from a season card.
class _EpisodeGrid extends StatelessWidget {
  final String showName;
  final String seasonName;
  final List<MediaItem> episodes;

  const _EpisodeGrid({
    required this.showName,
    required this.seasonName,
    required this.episodes,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return Scaffold(
      appBar: AppBar(title: Text(seasonName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: episodes.length,
        itemBuilder: (_, i) {
          final ep = episodes[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: ep)),
            ),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Stack(
                    children: [
                      ThumbnailImage(
                        thumbnailUrl: ep.thumbnailPath,
                        videoPath: ep.path,
                        category: ep.category,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: WatchedProgressBar(filePath: ep.path),
                      ),
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
