import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/ui/screens/player_screen.dart';
import 'package:watch/services/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String? _q;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(filteredMediaProvider);
    final q = (_q ?? '').toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          decoration: const InputDecoration(hintText: 'search media...', border: InputBorder.none),
          onChanged: (v) => setState(() => _q = v.isEmpty ? null : v),
          autofocus: true,
          onSubmitted: (_) {
            final hits = q.isEmpty ? null : _filter(all.value ?? [], q);
            if (hits != null && hits.isNotEmpty) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: hits.first)));
            }
          },
        ),
        actions: [
          if (_q != null && _q!.isNotEmpty)
            IconButton(icon: const Icon(Icons.close), onPressed: () { _ctrl.clear(); setState(() => _q = null); _focus.requestFocus(); }),
        ],
      ),
      body: all.when(
        data: (items) {
          if (q.isEmpty) return const Center(child: Text('type to search...'));
          final hits = _filter(items, q);
          if (hits.isEmpty) return const Center(child: Text('no results.'));
          return ListView.builder(
            itemCount: hits.length,
            itemBuilder: (_, i) {
              final m = hits[i];
              final iconData = m.type == MediaType.audio ? Icons.music_note : Icons.videocam;
              return ListTile(
                leading: Icon(iconData),
                title: Text(m.title),
                subtitle: Text(m.seriesName ?? m.path.split('/').last),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(mediaItem: m)));
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

  List<MediaItem> _filter(List<MediaItem> items, String q) {
    return items.where((m) => m.title.toLowerCase().contains(q))
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }
}
