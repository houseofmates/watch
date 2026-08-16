import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/widgets/thumbnail_image.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';

/// Category detail page reached via URL slug:
///   /shows/<show-slug>      → seasons as horizontal rows, each with episode thumbnails
///   /movies/<group-slug>    → individual movies grid
///   /porn/<studio-slug>     → individual videos grid
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
      appBar: AppBar(title: Text(title)),
      body: itemsAsync.when(
        data: (items) {
          final catItems = items.where((m) => m.category == widget.category).toList();
          if (catItems.isEmpty) {
            return const Center(child: Text('nothing here yet.'));
          }

          // Filter items matching the slug.
          // Shows match by seriesName (show folder); movies/porn match by
          // seriesName (group dir/studio) or individual title (standalone).
          late final List<MediaItem> groupItems;
          if (widget.category == MediaCategory.shows) {
            groupItems = catItems.where(
              (m) => m.seriesName != null && slugify(m.seriesName!) == widget.slug,
            ).toList();
          } else {
            groupItems = catItems.where((m) {
              if (m.seriesName != null) return slugify(m.seriesName!) == widget.slug;
              return slugify(m.title) == widget.slug;
            }).toList();
          }

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
            if (seasons.length == 1) {
              // Single season — show episodes directly in a grid
              final episodes = seasons.values.first;
              return _EpisodeGrid(seasonName: seasons.keys.first, episodes: episodes);
            }
            return _SeasonList(seasons: seasons, category: widget.category);
          }

          // Movies and porn: show individual items in a grid
          return _ItemGrid(
            category: widget.category,
            items: groupItems,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error: $e')),
      ),
    );
  }
}

/// List of seasons, each with a horizontal scrollable row of episode thumbnails.
class _SeasonList extends StatelessWidget {
  final Map<String, List<MediaItem>> seasons;
  final String category;

  const _SeasonList({required this.seasons, required this.category});

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
        final allEps = episodes;
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
              Text('${allEps.length} episodes',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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

  const _ItemGrid({required this.category, required this.items});

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

/// Full-screen episode grid (for single-season shows).
class _EpisodeGrid extends StatelessWidget {
  final String seasonName;
  final List<MediaItem> episodes;

  const _EpisodeGrid({required this.seasonName, required this.episodes});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return GridView.builder(
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
    );
  }
}
