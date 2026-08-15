import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;
  const PlayerScreen({super.key, required this.mediaItem});
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  AudioPlayer? _audio;
  ChewieController? _chewie;
  bool _ready = false;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    if (widget.mediaItem.type == MediaType.audio) {
      _audio = AudioPlayer();
      await _audio!.setSourceDeviceFile(widget.mediaItem.path);
      _audio!.onPlayerComplete.listen((_) => setState(() {}));
    } else {
      final c = VideoPlayerController.file(File(widget.mediaItem.path));
      await c.initialize();
      _chewie = ChewieController(videoPlayerController: c, autoPlay: true, looping: false);
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() { _audio?.dispose(); _chewie?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.mediaItem.title)),
    body: !_ready
        ? const Center(child: CircularProgressIndicator())
        : widget.mediaItem.type == MediaType.audio
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.music_note, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(widget.mediaItem.title, textAlign: TextAlign.center,
                     style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                StreamBuilder<PlayerState>(
                  stream: _audio!.onPlayerStateChanged,
                  builder: (_, snap) {
                    final ps = snap.data;
                    final playing = ps == PlayerState.playing;
                    return ElevatedButton.icon(
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      label: Text(playing ? 'pause' : 'play'),
                      onPressed: () => playing ? _audio!.pause() : _audio!.resume(),
                    );
                  },
                ),
                StreamBuilder<Duration?>(
                  stream: _audio!.onDurationChanged,
                  builder: (_, d) {
                    final dur = d.data;
                    if (dur == null) return const SizedBox.shrink();
                    return StreamBuilder<Duration>(
                      stream: _audio!.onPositionChanged,
                      builder: (_, p) {
                        final pos = p.data ?? Duration.zero;
                        return Slider(
                          value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                          max: dur.inMilliseconds.toDouble(),
                          onChanged: (v) async =>
                              _audio!.seek(Duration(milliseconds: v.toInt())),
                        );
                      },
                    );
                  },
                ),
              ])
            : Chewie(controller: _chewie!),
      );
}
