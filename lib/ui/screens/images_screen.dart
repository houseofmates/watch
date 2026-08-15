import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/screens/image_viewer_screen.dart';
import 'package:watch/services/providers.dart';

class ImagesScreen extends ConsumerWidget {
  const ImagesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMediaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('images')),
      body: items.when(
        data: (all) {
          final imgs = all.where((m) => m.category == MediaCategory.images).toList();
          final Map<String, List<MediaItem>> albums = {};
          for (final m in imgs) albums.putIfAbsent(m.seriesName ?? 'unknown', () => []).add(m);
          if (albums.isEmpty) return const Center(child: Text('no images found.'));
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: albums.length,
            itemBuilder: (_, i) {
              final e = albums.entries.elementAt(i);
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ImageViewerScreen(path: e.value.first.path, title: e.key)),
                ),
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: e.value.first.albumArtPath != null
                            ? Image.file(File(e.value.first.albumArtPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image)))
                            : Container(color: Colors.grey[800], child: const Icon(Icons.photo, size: 40)),
                      ),
                      Padding(padding: const EdgeInsets.all(4), child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
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
}
