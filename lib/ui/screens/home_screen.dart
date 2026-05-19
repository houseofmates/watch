import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/widgets/media_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pornEnabled = ref.watch(pornToggleProvider);
    final categories = MediaCategory.values.where(
      (c) => c != MediaCategory.all && (c != MediaCategory.porn || pornEnabled),
    ).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('watch'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search'))],
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
      'music': Icons.music_note,
      'images': Icons.photo_library,
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
            Icon(catIcon[category], size: 20),
            const SizedBox(width: 8),
            Text(category.toUpperCase(), style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text('${groupsAsync.value?.length ?? 0}'),
          ]),
        ),
        groupsAsync.when(
          data: (groups) => groups.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child: Text('nothing here yet.', style: TextStyle(color: Colors.grey)))
              : SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: groups.length,
                    itemBuilder: (_, j) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: MediaCard(group: groups[j]),
                    ),
                  ),
                ),
          loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('error: $e')),
        ),
        const Divider(),
      ],
    );
  }
}
