import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
<<<<<<< Updated upstream
      await _audio!.setSourceDeviceFile(widget.mediaItem.path);
      _audio!.onPlayerComplete.listen((_) => setState(() {}));
=======
      if (kIsWeb) {
        await _audio!.setSourceUrl(widget.mediaItem.path);
      } else {
        await _audio!.setSourceDeviceFile(widget.mediaItem.path);
      }
      _audio!.onPlayerComplete.listen((_) {
        PlaybackStateRepo.clearPosition(widget.mediaItem.path);
        setState(() {});
      });
      _audio!.onPositionChanged.listen((pos) => _autoSave());
      if (savedMs != null && savedMs > 5000) {
        _audio!.seek(Duration(milliseconds: savedMs));
      }
>>>>>>> Stashed changes
    } else {
      final c = kIsWeb
          ? VideoPlayerController.network(widget.mediaItem.path)
          : VideoPlayerController.file(File(widget.mediaItem.path));
      await c.initialize();
      _chewie = ChewieController(videoPlayerController: c, autoPlay: true, looping: false);
    }
    if (mounted) setState(() => _ready = true);
  }

<<<<<<< Updated upstream
  @override
  void dispose() { _audio?.dispose(); _chewie?.dispose(); super.dispose(); }
=======
  Future<void> _autoSave() async {
    final now = DateTime.now();
    if (now.difference(_lastSave).inSeconds < 5) return;
    _lastSave = now;
    int? pos;
    if (_audio != null) return; // handled by stream listener
    if (_chewie != null) {
      pos = _chewie!.videoPlayerController.value.position.inMilliseconds;
    }
    if (pos != null && pos > 0) {
      final dur = _chewie!.videoPlayerController.value.duration.inMilliseconds;
      await PlaybackStateRepo.savePosition(widget.mediaItem.path, pos, durationMs: dur);
    }
  }
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
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
=======
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('cancel')),
        ],
      ),
    );
  }

  Future<void> _castTo(CastDevice device) async {
    try {
      await CastService.startFileServer(widget.mediaItem.path);
      final url = await CastService.fileUrl;
      final ok = await CastService.cast(device.location, url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'casting to ${device.name}' : 'cast failed'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('cast error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _saveFinalPosition();
    CastService.stopFileServer();
    _focusNode.dispose();
    _audio?.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  void _saveFinalPosition() {
    if (_chewie != null) {
      final c = _chewie!.videoPlayerController.value;
      final pos = c.position.inMilliseconds;
      if (pos > 0) PlaybackStateRepo.savePosition(widget.mediaItem.path, pos, durationMs: c.duration.inMilliseconds);
    }
  }

  static String _fmtMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final h = m ~/ 60;
    final secs = (s % 60).toString().padLeft(2, '0');
    if (h > 0) return '$h:${(m % 60).toString().padLeft(2, '0')}:$secs';
    return '${m % 60}:$secs';
  }
}
>>>>>>> Stashed changes
