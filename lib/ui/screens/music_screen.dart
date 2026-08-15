import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/services/providers.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredMediaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('music')),
      body: items.when(
        data: (all) {
          final music = all.where((m) => m.category == MediaCategory.music).toList();
          final Map<String?, List<MediaItem>> albums = {};
          for (final m in music) albums.putIfAbsent(m.seriesName, () => []).add(m);
          if (albums.isEmpty) return const Center(child: Text('no music found.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: albums.length,
            itemBuilder: (_, i) {
              final e = albums.entries.elementAt(i);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: e.value.first.albumArtPath != null
                        ? Image.file(File(e.value.first.albumArtPath!), width: 56, height: 56, fit: BoxFit.cover)
                        : const Icon(Icons.album, size: 56),
                  ),
                  title: Text(e.key ?? 'unknown', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${e.value.length} tracks'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => _TrackList(albumName: e.key ?? 'unknown', tracks: e.value)),
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

<<<<<<< Updated upstream
=======
class _SortDropdown extends ConsumerWidget {
  const _SortDropdown();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(sortModeProvider);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: 'sort by',
      initialValue: mode,
      onSelected: (v) => ref.read(sortModeProvider.notifier).state = v,
      itemBuilder: (_) => _sortOptions.map((o) => PopupMenuItem(value: o.$1, child: Text(o.$2))).toList(),
    );
  }
}

class _AlbumsGrid extends ConsumerWidget {
  final Map<String?, List<MediaItem>> albums;
  const _AlbumsGrid({required this.albums});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortMode = ref.watch(sortModeProvider);
    final w = MediaQuery.of(context).size.width;
    final cols = w < 600 ? 2 : w < 1024 ? 3 : 4;
    final groups = albums.entries.map((e) => MediaGroup(
      name: e.key ?? 'unknown', category: MediaCategory.music,
      coverArtPath: e.value.first.albumArtPath, items: e.value,
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
            MaterialPageRoute(builder: (_) => _TrackList(albumName: group.name, tracks: group.items)),
          ),
          child: Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: group.coverArtPath != null
                      ? (kIsWeb
                          ? Image.network(group.coverArtPath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _AlbumPlaceholder())
                          : Image.file(File(group.coverArtPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _AlbumPlaceholder()))
                      : const _AlbumPlaceholder(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(group.items.first.subtitle.isEmpty ? '${group.itemCount} tracks' : group.items.first.subtitle,
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

class _AlbumPlaceholder extends StatelessWidget {
  const _AlbumPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xff1a1a3a),
    child: Center(child: Icon(Icons.album, size: 44, color: Color(0xff3c9fdd))),
  );
}

>>>>>>> Stashed changes
class _TrackList extends StatelessWidget {
  final String albumName;
  final List<MediaItem> tracks;
  const _TrackList({required this.albumName, required this.tracks});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(tracks[i].title),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: tracks[i]))),
        ),
      ),
    );
  }
}
