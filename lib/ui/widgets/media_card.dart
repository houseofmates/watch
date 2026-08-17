import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/widgets/thumbnail_image.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';

/// Build a slug-based route path for a group within a category.
/// Returns e.g. "/shows/my-gym-partners-a-monkey" or "/movies/standalone".
String _routeForGroup(String category, String groupName) {
  final slug = groupName == 'Standalone' ? 'standalone' : slugify(groupName);
  return '/$category/$slug';
}

String _formatSubtitle(MediaGroup group) {
  // For shows: show season/episode counts, not duration
  if (group.category == MediaCategory.shows) {
    final totalEpisodes = group.episodeCount ?? group.itemCount;
    final epSuffix = totalEpisodes == 1 ? '' : 's';
    if (group.seasonCount != null && group.seasonCount! > 0) {
      final s = group.seasonCount!;
      final sSuffix = s == 1 ? '' : 's';
      return '$s season$sSuffix, $totalEpisodes episode$epSuffix';
    }
    return '$totalEpisodes episode$epSuffix';
  }
  // For movies/porn: show item count
  final count = group.itemCount;
  final suffix = count == 1 ? '' : 's';
  return '$count item$suffix';
}

/// A reusable gallery card for media groups (shows, movies, porn).
///
/// [aspectRatio] controls the thumbnail image proportions:
///   0.8  → ~4:5 (slightly wider than 2:3, good for TMDb posters)
///   0.75 → 3:4 (standard poster)
///   1.6+ → widescreen (good for porn video screenshots)
class MediaCard extends StatelessWidget {
  final MediaGroup group;
  final VoidCallback? onTap;
  final double aspectRatio;
  final double width;
  final String? subtitle;

  const MediaCard({
    super.key,
    required this.group,
    this.onTap,
    this.aspectRatio = 0.75,
    this.width = 160,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final firstItem = group.items.isNotEmpty ? group.items.first : null;
    final videoPath =
        firstItem?.type == MediaType.video ? firstItem?.path : null;

    return GestureDetector(
      onTap: onTap ??
          () {
            final route = _routeForGroup(group.category, group.name);
            context.go(route);
          },
      child: SizedBox(
        width: width,
        child: Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image area with fixed aspect ratio
              SizedBox(
                height: width / aspectRatio,
                child: Stack(
                  children: [
                    ThumbnailImage(
                      thumbnailUrl: group.coverArtPath,
                      videoPath: videoPath,
                      category: group.category,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    if (videoPath != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: WatchedProgressBar(filePath: videoPath),
                      ),
                  ],
                ),
              ),
              // Title + subtitle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: Theme.of(context).cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle ?? _formatSubtitle(group),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
