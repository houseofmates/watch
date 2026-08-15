import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/widgets/watched_progress_bar.dart';
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
          for (final m in porn) {
            byStudio.putIfAbsent(m.seriesName ?? 'unknown', () => []).add(m);
          }
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
  const StudioVideoGrid({super.key, required this.studioName, required this.videos});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    return Scaffold(
      appBar: AppBar(title: Text(studioName)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75,
        ),
        itemCount: videos.length,
        itemBuilder: (_, i) {
          final m = videos[i];
          final placeholder = const _PornPlaceholder();
          final thumb = m.thumbnailPath;
          return GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m))),
            child: Card(
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Stack(
                    children: [
                      thumb != null
                          ? (kIsWeb
                              ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
                              : Image.file(File(thumb), fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder))
                          : placeholder,
                      Positioned(left: 0, right: 0, bottom: 0, child: WatchedProgressBar(filePath: m.path)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: Theme.of(context).cardColor,
                    child: Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
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
