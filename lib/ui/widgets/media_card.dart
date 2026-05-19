import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';

class MediaCard extends StatelessWidget {
  final MediaGroup group;
  const MediaCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final route = {
          MediaCategory.music: '/music',
          MediaCategory.images: '/images',
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
                    Text('${group.itemCount} items', style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
    final cover = group.coverArtPath;
    if (cover != null && cover.isNotEmpty) {
      return Image.file(File(cover), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _Icon(group.category));
    }
    return _Icon(group.category);
  }
}

class _Icon extends StatelessWidget {
  final String category;
  const _Icon(this.category);
  @override
  Widget build(BuildContext context) {
    final iconMap = {
      MediaCategory.music: Icons.album,
      MediaCategory.images: Icons.photo,
      MediaCategory.shows: Icons.tv,
      MediaCategory.movies: Icons.movie,
      MediaCategory.porn: Icons.lock,
    };
    final icon = iconMap[category] ?? Icons.folder;
    return ColoredBox(
      color: const Color(0xff1a1a3a),
      child: Center(child: Icon(icon, size: 44, color: Colors.deepPurple.shade300)),
    );
  }
}
