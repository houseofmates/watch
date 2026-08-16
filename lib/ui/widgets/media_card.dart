import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/widgets/thumbnail_image.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';

String _formatSubtitle(MediaGroup group) {
  final durations = group.items
      .where((item) => item.durationSeconds != null)
      .map((item) => item.durationSeconds!.toDouble())
      .toList();
  if (durations.isEmpty) {
    return '${group.itemCount} item${group.itemCount != 1 ? 's'}';
  }
  final total = durations.fold(0.0, (a, b) => a + b);
  final h = (total / 3600).floor();
  final m = ((total % 3600) / 60).floor();
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

class MediaCard extends StatelessWidget {
  final MediaGroup group;
  final VoidCallback? onTap;
  const MediaCard({super.key, required this.group, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        final route = {
          MediaCategory.shows: '/shows',
          MediaCategory.movies: '/movies',
          MediaCategory.porn: '/porn',
        }[group.category];
        if (route != null) context.go(route);
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
                    Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
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
