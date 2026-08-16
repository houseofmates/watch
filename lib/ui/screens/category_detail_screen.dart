import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/widgets/thumbnail_image.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';

/// Category detail page reached via URL slug:
///   /shows/<show-slug>      → seasons → episodes grid
///   /movies/<group-slug>    → individual movies grid (or "standalone")
///   /porn/<studio-slug>     → individual videos grid (or "unknown")
///
/// Each thumbnail is right-clickable (web) / long-pressable (mobile)
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
      appBar: AppBar(
        title: Text(title),
      ),
      body: itemsAsync.when(
        data: (items) {
          final catItems = items.where((m) => m.category == widget.category).toList();
          if (catItems.isEmpty) {
            return const Center(child: Text('nothing here yet.'));
          }

          // Resolve slug → group name
          final allNames = catItems.map((m) => m.seriesName).toSet();
          final groupName = _resolveSlug(widget.slug, allNames);

          // Filter items for this group
          final groupItems = groupName == null
              ? catItems.where((m) => m.seriesName == null).toList()
              : catItems.where((m) => m.seriesName == groupName).toList();

          if (groupItems.isEmpty) {
            return const Center(child: Text('no items found for this slug.'));
          }

          if (widget.category == MediaCategory.shows) {
            // Group episodes by season
            final seasons = <String, List<MediaItem>>{};
            for (final item in groupItems) {
              final ssn = item.season ?? 'Unknown';
              seasons.putIfAbsent(ssn, () => []).add(item);
            }
            return _SeasonGrid(
              showName: groupName ?? widget.slug,
              seasons: seasons,
              onSeasonTap: (seasonName, episodes) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EpisodeGridScreen(
                    seasonName: seasonName,
                    episodes: episodes,
                  ),
                ));
              },
            );
          }

          // Movies and porn: show individual items in a flat grid
          return _ItemGrid(
            category: widget.category,
            items: groupItems,
            groupName: groupName ?? widget.slug,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
      ),
    );
  }

  String? _resolveSlug(String slug, Set<String?> names) {
    // Handle "standalone" / "unknown" slug for null seriesName
    if (slug == 'standalone' || slug == 'unknown') return null;
    for (final n in names) {
      if (n != null && slugify(n) == slug) return n;
    }
    // Fallback: try matching against individual titles
    return null;
  }
}

/// Horizontal scrollable season cards for a show.
class _SeasonGrid extends StatelessWidget {
  final String showName;
  final Map<String, List<MediaItem>> seasons;
  final void Function(String seasonName, List<MediaItem> episodes) onSeasonTap;

  const _SeasonGrid({
    required this.showName,
    required this.seasons,
    required this.onSeasonTap,
  });

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return const Center(child: Text('no seasons found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: seasons.length,
      itemBuilder: (_, i) {
        final entry = seasons.entries.elementAt(i);
        final episodes = entry.value;
        final firstVideo = episodes.firstWhere(
          (m) => m.type == MediaType.video,
          orElse: () => episodes.first,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: episodes.length,
                  itemBuilder: (_, j) {
                    final ep = episodes[j];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Card(
                                clipBehavior: Clip.hardEdge,
                                child: Stack(
                                  children: [
                                    ThumbnailImage(
                                      thumbnailUrl: ep.thumbnailPath,
                                      videoPath: ep.path,
                                      category: ep.category,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      left: 0, right: 0, bottom: 0,
                                      child: WatchedProgressBar(filePath: ep.path),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              ep.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Grid of individual media items (movies, porn videos, episodes).
class _ItemGrid extends StatelessWidget {
  final String category;
  final List<MediaItem> items;
  final String groupName;

  const _ItemGrid({
    required this.category,
    required this.items,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final m = items[i];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)),
          ),
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: Stack(
                  children: [
                    ThumbnailImage(
                      thumbnailUrl: m.thumbnailPath,
                      videoPath: m.path,
                      category: m.category,
                      fit: BoxFit.cover,
                    ),
                    if (m.type == MediaType.video)
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: WatchedProgressBar(filePath: m.path),
                      ),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: Theme.of(context).cardColor,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (m.durationSeconds != null)
                      Text(_formatDuration(m.durationSeconds!),
                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

/// Full-screen episode grid (navigated from season card tap).
class EpisodeGridScreen extends StatelessWidget {
  final String seasonName;
  final List<MediaItem> episodes;

  const EpisodeGridScreen({super.key, required this.seasonName, required this.episodes});

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
                      ),
                      Positioned(left: 0, right: 0, bottom: 0, child: WatchedProgressBar(filePath: ep.path)),
                    ],
                  ))),
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
