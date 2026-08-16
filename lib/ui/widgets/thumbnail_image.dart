import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:watch/core/constants.dart';

/// Derive a media identifier for override API calls.
/// On web: strips /api/thumbnail/ prefix from the thumbnail URL.
/// On native: hashes the video path.
String _mediaIdFor(String? thumbnailUrl, String? videoPath) {
  if (thumbnailUrl != null && thumbnailUrl.startsWith('/api/thumbnail/')) {
    return thumbnailUrl.substring('/api/thumbnail/'.length);
  }
  if (videoPath != null && videoPath.isNotEmpty) {
    var h = 5381;
    for (final c in videoPath.codeUnits) {
      h = ((h << 5) + h + c) & 0x7FFFFFFF;
    }
    return h.toRadixString(16);
  }
  return '';
}

/// Renders a thumbnail for a media item.
///
/// Resolution order:
///   1. Local override (native only — custom image set via long-press)
///   2. [thumbnailUrl] — server-generated thumbnail (web) or local file (native)
///   3. On native: generate from [videoPath] via video_thumbnail (Android) or ffmpeg (Linux)
///   4. Fallback: category icon placeholder
///
/// Right-click (web/desktop) or long-press (mobile) on the thumbnail opens a
/// context menu to swap the image via URL or device upload, or reset to default.
class ThumbnailImage extends StatefulWidget {
  final String? thumbnailUrl;
  final String? videoPath;
  final String category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool enableOverride;
  final VoidCallback? onOverrideApplied;

  const ThumbnailImage({
    super.key,
    this.thumbnailUrl,
    this.videoPath,
    required this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.enableOverride = true,
    this.onOverrideApplied,
  });

  @override
  State<ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<ThumbnailImage> {
  String? _localThumbPath;
  String? _overridePath; // custom override path (native)
  int _refreshCounter = 0; // forces Image.network to re-fetch after override

  @override
  void initState() {
    super.initState();
    _loadOverrideAndGenerate();
  }

  @override
  void didUpdateWidget(covariant ThumbnailImage old) {
    super.didUpdateWidget(old);
    if (old.thumbnailUrl != widget.thumbnailUrl || old.videoPath != widget.videoPath) {
      _loadOverrideAndGenerate();
    }
  }

  Future<void> _loadOverrideAndGenerate() async {
    final mediaId = _mediaIdFor(widget.thumbnailUrl, widget.videoPath);
    if (mediaId.isEmpty) {
      _generateNativeThumbnail();
      return;
    }

    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString('thumb_override_$mediaId');
      if (override != null && File(override).existsSync() && File(override).lengthSync() > 0) {
        if (mounted) setState(() => _overridePath = override);
        return;
      }
    }

    _generateNativeThumbnail();
  }

  Future<void> _generateNativeThumbnail() async {
    if (kIsWeb) return;
    final videoPath = widget.videoPath;
    if (videoPath == null) return;

    final key = _mediaIdFor(widget.thumbnailUrl, widget.videoPath);
    final cacheDir = await getTemporaryDirectory();
    final cacheRoot = Directory('${cacheDir.path}/watch_thumbs');
    if (!await cacheRoot.exists()) await cacheRoot.create(recursive: true);
    final cachePath = '${cacheRoot.path}/$key.jpg';

    if (File(cachePath).existsSync()) {
      if (mounted) setState(() => _localThumbPath = cachePath);
      return;
    }

    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        maxHeight: 300,
        maxWidth: 300,
        quality: 25,
        timeMs: 10000,
      );
      if (thumb != null) {
        await File(thumb).copy(cachePath);
        if (mounted) setState(() => _localThumbPath = cachePath);
        return;
      }
    } catch (_) {}

    try {
      await Process.run('ffmpeg', [
        '-y', '-ss', '10', '-i', videoPath,
        '-frames:v', '1', '-q:v', '2', '-vf', 'scale=300:-1',
        cachePath,
      ]).timeout(const Duration(seconds: 60));
      if (File(cachePath).existsSync() && File(cachePath).lengthSync() > 0 && mounted) {
        setState(() => _localThumbPath = cachePath);
      }
    } catch (_) {}
  }

  Future<void> _forceRegenerate() async {
    if (kIsWeb) {
      setState(() {
        _refreshCounter++;
        _overridePath = null;
      });
    } else {
      setState(() {
        _overridePath = null;
        _localThumbPath = null;
      });
      _loadOverrideAndGenerate();
    }
  }

  // ── Override management ──────────────────────────────────────────────

  void _showContextMenu(BuildContext ctx, Offset position) {
    final mediaId = _mediaIdFor(widget.thumbnailUrl, widget.videoPath);
    if (mediaId.isEmpty) return;

    showMenu(
      context: ctx,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 0.1,
        position.dy + 0.1,
      ),
      items: [
        PopupMenuItem(
          child: Row(children: [
            Icon(Icons.link, size: 16, color: Theme.of(ctx).colorScheme.secondary),
            SizedBox(width: 8),
            Text('use image url'),
          ]),
          onTap: () => _onSetFromUrl(mediaId),
        ),
        PopupMenuItem(
          child: Row(children: [
            Icon(Icons.upload, size: 16, color: Theme.of(ctx).colorScheme.secondary),
            SizedBox(width: 8),
            Text('upload from device'),
          ]),
          onTap: () => _onUploadFromFile(mediaId),
        ),
        PopupMenuItem(
          child: Row(children: [
            Icon(Icons.refresh, size: 16, color: Theme.of(ctx).colorScheme.primary),
            SizedBox(width: 8),
            Text('reset to default'),
          ]),
          onTap: () => _onReset(mediaId),
        ),
      ],
    );
  }

  void _onSetFromUrl(String mediaId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('image url'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'https://example.com/image.jpg'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('cancel')),
          TextButton(
            onPressed: () {
              final url = ctrl.text.trim();
              Navigator.of(context).pop();
              if (url.isNotEmpty) _applyOverride(mediaId, imageUrl: url);
            },
            child: const Text('set'),
          ),
        ],
      ),
    );
  }

  void _onUploadFromFile(String mediaId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          final ok = await _applyOverride(mediaId, imageData: bytes);
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('thumbnail set'), backgroundColor: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error: $e'), backgroundColor: Theme.of(context).colorScheme.primary),
        );
      }
    }
  }

  void _onReset(String mediaId) async {
    final ok = await _removeOverride(mediaId);
    _forceRegenerate();
    widget.onOverrideApplied?.call();
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('thumbnail reset'), backgroundColor: Colors.green),
      );
    }
  }

  Future<bool> _applyOverride(String mediaId, {String? imageUrl, Uint8List? imageData}) async {
    try {
      Uint8List bytes;
      if (kIsWeb) {
        // Web: send to server
        final body = <String, dynamic>{};
        if (imageUrl != null) body['image_url'] = imageUrl;
        if (imageData != null) body['image_data'] = base64Encode(imageData);
        final resp = await http.post(
          Uri.parse('/api/thumbnail/override/$mediaId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        if (resp.statusCode != 200) return false;
      } else {
        // Native: save locally
        if (imageUrl != null) {
          final resp = await http.get(Uri.parse(imageUrl));
          if (resp.statusCode != 200) return false;
          bytes = resp.bodyBytes;
        } else {
          bytes = imageData!;
        }
        final cacheDir = await getTemporaryDirectory();
        final customDir = Directory('${cacheDir.path}/watch_custom_thumbs');
        if (!await customDir.exists()) await customDir.create(recursive: true);
        final path = '${customDir.path}/$mediaId.jpg';
        await File(path).writeAsBytes(bytes);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('thumb_override_$mediaId', path);
        setState(() => _overridePath = path);
      }
      widget.onOverrideApplied?.call();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error: $e'), backgroundColor: Theme.of(context).colorScheme.primary),
        );
      }
      return false;
    }
  }

  Future<bool> _removeOverride(String mediaId) async {
    try {
      if (kIsWeb) {
        final resp = await http.delete(Uri.parse('/api/thumbnail/override/$mediaId'));
        return resp.statusCode == 200;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final override = prefs.getString('thumb_override_$mediaId');
        if (override != null) {
          try { await File(override).delete(); } catch (_) {}
          await prefs.remove('thumb_override_$mediaId');
        }
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget image;

    // 1. Local override (native)
    if (_overridePath != null) {
      image = Image.file(
        File(_overridePath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // 2. Server-provided thumbnail URL or local file path
    else if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      if (widget.thumbnailUrl!.startsWith('http://') || widget.thumbnailUrl!.startsWith('https://')) {
        image = Image.network(
          widget.thumbnailUrl!,
          key: ValueKey('network_thumb_${_refreshCounter}'),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } else {
        image = Image.file(
          File(widget.thumbnailUrl!),
          key: ValueKey('file_thumb_${_refreshCounter}'),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }
    // 3. Native-generated thumbnail
    else if (_localThumbPath != null) {
      image = Image.file(
        File(_localThumbPath!),
        key: ValueKey('local_thumb_${_refreshCounter}'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // 4. Fallback: icon
    else {
      image = _placeholder();
    }

    if (widget.enableOverride) {
      image = GestureDetector(
        onSecondaryTapDown: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final pos = box.localToGlobal(details.localPosition);
          _showContextMenu(context, pos);
        },
        onLongPress: () {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final size = box.size;
          _showContextMenu(context, Offset(size.width / 2, size.height / 2));
        },
        child: image,
      );
    }

    return image;
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
