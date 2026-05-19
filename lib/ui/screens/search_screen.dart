import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/ui/screens/image_viewer_screen.dart';
import 'package:watch/services/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String? _q;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(filteredMediaProvider);
    final q = (_q ?? '').toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(hintText: 'search media...', border: InputBorder.none),
          onChanged: (v) => setState(() => _q = v.isEmpty ? null : v),
        ),
        actions: [
          if (_q != null && _q!.isNotEmpty)
            IconButton(icon: const Icon(Icons.close), onPressed: () { _ctrl.clear(); setState(() => _q = null); }),
        ],
      ),
      body: all.when(
        data: (items) {
          if (q.isEmpty) return const Center(child: Text('type to search...'));
          final hits = items.where((m) => m.title.toLowerCase().contains(q)).toList()
            ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          if (hits.isEmpty) return const Center(child: Text('no results.'));
          return ListView.builder(
            itemCount: hits.length,
            itemBuilder: (_, i) {
              final m = hits[i];
              final iconData = m.type == MediaType.audio ? Icons.music_note : m.type == MediaType.image ? Icons.image : Icons.videocam;
              return ListTile(
                leading: Icon(iconData),
                title: Text(m.title),
                subtitle: Text(m.seriesName ?? m.path.split('/').last),
                onTap: () {
                  if (m.type == MediaType.image) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ImageViewerScreen(path: m.path, title: m.title)));
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)));
                  }
                },
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
