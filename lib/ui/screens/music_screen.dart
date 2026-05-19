import 'dart:io';
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
