import 'package:flutter/material.dart';
import 'package:watch/services/playback_state_repo.dart';

class WatchedProgressBar extends StatelessWidget {
  final String filePath;
  const WatchedProgressBar({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double?>(
      future: _loadRatio(),
      builder: (_, snap) {
        final r = snap.data;
        if (r == null || r <= 0 || r >= 0.95) return const SizedBox.shrink();
        return LinearProgressIndicator(
          value: r,
          backgroundColor: const Color(0xff0a0a0a),
          valueColor: const AlwaysStoppedAnimation(Color(0xffffaf00)),
          minHeight: 3,
        );
      },
    );
  }

  Future<double?> _loadRatio() async {
    final pos = await PlaybackStateRepo.getPosition(filePath);
    final dur = await PlaybackStateRepo.getDuration(filePath);
    if (pos == null || dur == null || dur <= 0) return null;
    return pos / dur;
  }
}
