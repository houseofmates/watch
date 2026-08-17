import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/widgets/media_card.dart';

/// /porn — loose gallery of individual video cards (not dropdowns).
/// Each card shows a horizontal video screenshot with the title below.
/// Tap a card → play the video directly.
class PornScreen extends ConsumerWidget {
  const PornScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(pornToggleProvider);
    if (!enabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('adult content')),
        body: const Center(child: Text('this category is hidden.\nenable "show adult content" in settings.')),
      );
    }
    final items = ref.watch(filteredMediaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('adult content')),
      body: items.when(
        data: (all) {
          final porn = all.where((m) => m.category == MediaCategory.porn).toList();
          if (porn.isEmpty) return const Center(child: Text('no adult content found.'));
          final w = MediaQuery.of(context).size.width;
          final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
            ),
            itemCount: porn.length,
            itemBuilder: (_, i) {
              final m = porn[i];
              final group = MediaGroup(
                name: m.title,
                category: MediaCategory.porn,
                coverArtPath: m.thumbnailPath,
                items: [m],
              );
              return MediaCard(
                group: group,
                aspectRatio: 1.5, // widescreen for video screenshots
                width: 140,
                subtitle: _videoSubtitle(m),
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

  String _videoSubtitle(MediaItem m) {
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
      parts.add(m.extension);
    }
    return parts.isNotEmpty ? parts.join(' · ') : m.extension;
  }
}
