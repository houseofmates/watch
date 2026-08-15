<<<<<<< Updated upstream
=======
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
<<<<<<< Updated upstream
=======
import 'package:watch/ui/widgets/media_card.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';
>>>>>>> Stashed changes
import 'package:watch/services/providers.dart';

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
          final Map<String, List<MediaItem>> byStudio = {};
          for (final m in porn) byStudio.putIfAbsent(m.seriesName ?? 'unknown', () => []).add(m);
          if (byStudio.isEmpty) return const Center(child: Text('no adult content found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: byStudio.length,
            itemBuilder: (_, i) {
              final e = byStudio.entries.elementAt(i);
              return ExpansionTile(
                leading: const Icon(Icons.lock, size: 36),
                title: Text(e.key),
                subtitle: Text('${e.value.length} videos'),
                children: e.value.map((m) => ListTile(
                  title: Text(m.title),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m))),
                )).toList(),
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
<<<<<<< Updated upstream
=======

class _PornGrid extends ConsumerWidget {
  final Map<String, List<MediaItem>> studios;
  const _PornGrid({required this.studios});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortMode = ref.watch(sortModeProvider);
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    final groups = studios.entries.map((e) => MediaGroup(
      name: e.key, category: MediaCategory.porn, items: e.value,
    )).toList();
    final sorted = sortGroups(groups, sortMode);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final group = sorted[i];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StudioVideoGrid(studioName: group.name, videos: group.items)),
          ),
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _PornPlaceholder()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${group.itemCount} videos',
                          style: const TextStyle(color: Color(0xff3c9fdd), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PornPlaceholder extends StatelessWidget {
  const _PornPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xff1a1a3a),
    child: Center(child: Icon(Icons.lock, size: 44, color: Color(0xff3c9fdd))),
  );
}

class StudioVideoGrid extends StatelessWidget {
  final String studioName;
  final List<MediaItem> videos;
  const StudioVideoGrid({required this.studioName, required this.videos});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return Scaffold(
      appBar: AppBar(title: Text(studioName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: videos.length,
        itemBuilder: (_, i) {
          final m = videos[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)),
            ),
            onLongPress: () => showMediaContextMenu(context, m, onPlay: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)));
              }),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Stack(
                    children: [
                      m.thumbnailPath != null
                        ? (kIsWeb
                            ? Image.network(m.thumbnailPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _PornPlaceholder())
                            : Image.file(File(m.thumbnailPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _PornPlaceholder()))
                        : const _PornPlaceholder(),
                      Positioned(left: 0, right: 0, bottom: 0, child: WatchedProgressBar(filePath: m.path)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: Theme.of(context).cardColor,
                    child: Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
>>>>>>> Stashed changes
