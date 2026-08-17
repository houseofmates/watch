import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/widgets/media_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pornEnabled = ref.watch(pornToggleProvider);
    final categories = MediaCategory.values.where(
      (c) => c != MediaCategory.all && c != MediaCategory.discover && (c != MediaCategory.porn || pornEnabled),
    ).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('watch'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
          IconButton(icon: const Icon(Icons.explore), onPressed: () => context.push('/discover')),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (_, i) => _CategorySection(category: categories[i]),
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final String category;
  const _CategorySection({required this.category});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(filteredMediaProvider).whenData(
          (items) => groupMedia(items.where((m) => m.category == category).toList(), category),
        );
    final catIcon = {
      'shows': Icons.tv,
      'movies': Icons.movie,
      'porn': Icons.lock,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(children: [
            Icon(catIcon[category] ?? Icons.folder, size: 20),
            const SizedBox(width: 8),
            // Clickable category name → navigates to the full category page
            GestureDetector(
              onTap: () => context.go('/$category'),
              child: Text(
                category.toLowerCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${groupsAsync.value?.length ?? 0}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/$category'),
              child: Text('see all', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            ),
          ]),
        ),
        groupsAsync.when(
          data: (groups) => groups.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child: Text('nothing here yet.', style: TextStyle(color: Colors.grey)))
              : SizedBox(
                  height: category == 'porn' ? 180 : 245,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: groups.length,
                    itemBuilder: (_, j) {
                      final group = groups[j];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: MediaCard(
                          group: group,
                          aspectRatio: category == 'porn' ? 1.3 : 0.85,
                          width: category == 'porn' ? 200 : 170,
                          subtitle: category == 'porn'
                              ? _pornDurationSubtitle(group)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
          loading: () => SizedBox(height: category == 'porn' ? 180 : 245, child: const Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('error: $e')),
        ),
        const Divider(),
      ],
    );
  }
}

/// Format duration for porn cards on the home screen.
/// Shows "1h 23m" or "45m" for the first video item in the group.
String _pornDurationSubtitle(MediaGroup group) {
  if (group.items.isEmpty) return '';
  final item = group.items.firstWhere(
    (i) => i.type == MediaType.video,
    orElse: () => group.items.first,
  );
  final d = item.durationSeconds;
  if (d == null || d <= 0) return '';
  final h = d ~/ 3600;
  final m = (d % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}
