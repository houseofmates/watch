import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';
import 'package:watch/services/playback_state_repo.dart';

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
  int? _savedMs;
  DateTime _lastSave = DateTime(0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.mediaItem.type == MediaType.audio) {
      _audio = AudioPlayer();
      if (kIsWeb) {
        await _audio!.setUrl(widget.mediaItem.path);
      } else {
        await _audio!.setSourceDeviceFile(widget.mediaItem.path);
      }
      _audio!.onPlayerComplete.listen((_) {
        PlaybackStateRepo.clearPosition(widget.mediaItem.path);
        setState(() {});
      });
      _audio!.onPositionChanged.listen((_) => _autoSave());
      _savedMs = await PlaybackStateRepo.getPosition(widget.mediaItem.path);
      if (_savedMs != null && _savedMs! > 5000) {
        await _audio!.seek(Duration(milliseconds: _savedMs!));
      }
    } else {
      final c = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(widget.mediaItem.path))
          : VideoPlayerController.file(File(widget.mediaItem.path));
      await c.initialize();
      _savedMs = await PlaybackStateRepo.getPosition(widget.mediaItem.path);
      if (_savedMs != null && _savedMs! > 5000) {
        await c.seekTo(Duration(milliseconds: _savedMs!));
      }
      _chewie = ChewieController(
        videoPlayerController: c,
        autoPlay: true,
        looping: false,
      );
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _autoSave() async {
    final now = DateTime.now();
    if (now.difference(_lastSave).inSeconds < 5) return;
    _lastSave = now;
    int? pos;
    int? dur;
    if (_audio != null) {
      pos = (_audio!.currentState == PlayerState.playing
          ? await _audio!.getCurrentPosition()
          : null);
      dur = await _audio!.getDuration();
      if (pos != null && pos > 0) {
        await PlaybackStateRepo.savePosition(
          widget.mediaItem.path, pos, durationMs: dur,
        );
      }
    } else if (_chewie != null) {
      final val = _chewie!.videoPlayerController.value;
      pos = val.position.inMilliseconds;
      dur = val.duration.inMilliseconds;
      if (pos > 0 && dur > 0) {
        await PlaybackStateRepo.savePosition(
          widget.mediaItem.path, pos, durationMs: dur,
        );
      }
    }
  }

  @override
  void dispose() {
    _saveFinalPosition();
    _audio?.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  void _saveFinalPosition() {
    if (_chewie != null) {
      final c = _chewie!.videoPlayerController.value;
      final pos = c.position.inMilliseconds;
      if (pos > 0) {
        PlaybackStateRepo.savePosition(
          widget.mediaItem.path, pos, durationMs: c.duration.inMilliseconds,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.mediaItem.title)),
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : widget.mediaItem.type == MediaType.audio
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note, size: 80, color: Colors.deepPurple),
                      const SizedBox(height: 16),
                      Text(widget.mediaItem.title, textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall),
                      if (widget.mediaItem.subtitle != null)
                        Text(widget.mediaItem.subtitle!, textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
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
                      StreamBuilder<Duration?(
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
                    ],
                  )
                : Chewie(controller: _chewie!),
      );
}
