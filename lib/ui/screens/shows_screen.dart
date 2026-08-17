import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/widgets/media_card.dart';

/// /shows — gallery of show cards (not dropdowns).
/// Each card shows the show poster with season/episode count.
/// Tap a card → /shows/:slug (season gallery).
class ShowsScreen extends ConsumerWidget {
  const ShowsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMediaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('shows')),
      body: items.when(
        data: (all) {
          final shows = all.where((m) => m.category == MediaCategory.shows).toList();
          final groups = groupMedia(shows, MediaCategory.shows);
          if (groups.isEmpty) return const Center(child: Text('no shows found.'));
          final w = MediaQuery.of(context).size.width;
          final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.65,
            ),
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final group = groups[i];
              return MediaCard(
                group: group,
                aspectRatio: 0.8,
                width: 140,
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
