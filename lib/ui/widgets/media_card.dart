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

class MediaCard extends StatelessWidget {
  final MediaGroup group;
  final VoidCallback? onTap;
  const MediaCard({super.key, required this.group, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        final route = _routeForGroup(group.category, group.name);
        context.go(route);
      },
      child: SizedBox(
        width: 160,
        child: Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Cover(group: group),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                    Text(_formatSubtitle(group), style: const TextStyle(color: Colors.grey, fontSize: 11)),
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

class _Cover extends StatelessWidget {
  final MediaGroup group;
  const _Cover({required this.group});
  @override
  Widget build(BuildContext context) {
    final fp = _firstVideoPath;
    Widget image = ThumbnailImage(
      thumbnailUrl: group.coverArtPath,
      videoPath: fp,
      category: group.category,
      fit: BoxFit.cover,
    );
    if (fp == null) return image;
    return Stack(
      children: [
        image,
        Positioned(left: 0, right: 0, bottom: 0, child: WatchedProgressBar(filePath: fp)),
      ],
    );
  }

  String? get _firstVideoPath {
    for (final item in group.items) {
      if (item.type == MediaType.video) return item.path;
    }
    return null;
  }
}
