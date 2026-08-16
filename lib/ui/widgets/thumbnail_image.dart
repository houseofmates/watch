import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:watch/core/constants.dart';

/// Renders a thumbnail for a media item.
///
/// Resolution order:
///   1. [thumbnailUrl] — server-generated thumbnail (web) or local file (native)
///   2. On native: generate from [videoPath] via video_thumbnail (Android) or ffmpeg (Linux)
///   3. Fallback: category icon placeholder
class ThumbnailImage extends StatefulWidget {
  final String? thumbnailUrl;
  final String? videoPath;
  final String category;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ThumbnailImage({
    super.key,
    this.thumbnailUrl,
    this.videoPath,
    required this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<ThumbnailImage> {
  String? _localThumbPath;

  @override
  void initState() {
    super.initState();
    _generateNativeThumbnail();
  }

  Future<void> _generateNativeThumbnail() async {
    if (kIsWeb) return;
    final videoPath = widget.videoPath;
    if (videoPath == null) return;

    final key = _hashPath(videoPath);
    final cacheDir = await getTemporaryDirectory();
    final cacheRoot = Directory('${cacheDir.path}/watch_thumbs');
    if (!await cacheRoot.exists()) await cacheRoot.create(recursive: true);
    final cachePath = '${cacheRoot.path}/$key.jpg';

    // Check cache first
    if (File(cachePath).existsSync()) {
      if (mounted) setState(() => _localThumbPath = cachePath);
      return;
    }

    // Try video_thumbnail (Android/iOS)
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        maxHeight: 300,
        maxWidth: 300,
        quality: 25,
        timeMs: 10000, // 10 seconds
      );
      if (thumb != null) {
        await File(thumb).copy(cachePath);
        if (mounted) setState(() => _localThumbPath = cachePath);
        return;
      }
    } catch (_) {
      // video_thumbnail not available on this platform — fall through to ffmpeg
    }

    // Fallback: ffmpeg (Linux desktop, if installed)
    try {
      await Process.run('ffmpeg', [
        '-y', '-ss', '10', '-i', videoPath,
        '-frames:v', '1', '-q:v', '2', '-vf', 'scale=300:-1',
        cachePath,
      ]).timeout(const Duration(seconds: 60));
      if (File(cachePath).existsSync() && File(cachePath).lengthSync() > 0 && mounted) {
        setState(() => _localThumbPath = cachePath);
      }
    } catch (_) {
      // ffmpeg not available or timed out — leave thumbnail as null
    }
  }

  static String _hashPath(String path) {
    var hash = 5381;
    for (final c in path.codeUnits) {
      hash = ((hash << 5) + hash + c) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Server-provided thumbnail URL or local file path
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      if (kIsWeb || widget.thumbnailUrl!.startsWith('http://') || widget.thumbnailUrl!.startsWith('https://')) {
        return Image.network(
          widget.thumbnailUrl!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
      return Image.file(
        File(widget.thumbnailUrl!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // 2. Native-generated thumbnail
    if (_localThumbPath != null) {
      return Image.file(
        File(_localThumbPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // 3. Fallback: icon
    return _placeholder();
  }

  Widget _placeholder() => ColoredBox(
        color: const Color(0xff0a0a0a),
        child: Center(
          child: Icon(
            _iconFor(widget.category),
            size: 44,
            color: const Color(0xff3c9fdd),
          ),
        ),
      );

  static IconData _iconFor(String category) => {
        MediaCategory.shows: Icons.tv,
        MediaCategory.movies: Icons.movie,
        MediaCategory.porn: Icons.lock,
      }[category] ??
      Icons.folder;
}
