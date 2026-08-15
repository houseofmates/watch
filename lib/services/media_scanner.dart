import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:watch/core/constants.dart';
import 'package:watch/models/media_item.dart';

class MediaScanner {
  final Map<String, String> mediaRoots;
  final bool pornEnabled;

  MediaScanner({required this.mediaRoots, this.pornEnabled = true});

  Future<List<MediaItem>> scanAll() async {
    final List<MediaItem> all = [];
    for (final entry in mediaRoots.entries) {
      final category = entry.key;
      final root = entry.value;
      if (!await Directory(root).exists()) continue;
      if (category == MediaCategory.porn && !pornEnabled) continue;
      final items = await _scanCategory(category, root);
      all.addAll(items);
    }
    all.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return all;
  }

  Future<List<MediaItem>> _scanCategory(String category, String root) async {
    switch (category) {
      case MediaCategory.music: return _scanMusic(root);
      case MediaCategory.images: return _scanImages(root);
      case MediaCategory.shows: return _scanShows(root);
      case MediaCategory.movies: return _scanMovies(root);
      case MediaCategory.porn: return _scanPorn(root);
      default: return [];
    }
  }

  Future<List<MediaItem>> _scanMusic(String root) async {
    final List<MediaItem> items = [];
    await for (final albumDir in _dirs(root)) {
      String? albumArt;
      for (final artFile in ['folder.jpg', 'cover.png', 'cover.jpg', 'art.jpg']) {
        if (await File(p.join(albumDir.path, artFile)).exists()) {
          albumArt = p.join(albumDir.path, artFile);
          break;
        }
      }
      await for (final track in _files(albumDir.path)) {
        final ext = p.extension(track.path).toLowerCase();
        if (!supportedAudioExts.contains(ext)) continue;
        final stat = await track.stat();
        items.add(MediaItem(
          path: track.path,
          category: MediaCategory.music,
          type: MediaType.audio,
          title: p.basenameWithoutExtension(track.path),
          albumArtPath: albumArt,
          fileSizeBytes: stat.size.toInt(),
          modified: stat.modified,
          extension: ext,
        ));
      }
    }
    return items;
  }

  Future<List<MediaItem>> _scanImages(String root) async {
    final List<MediaItem> items = [];
    await for (final albumDir in _dirs(root)) {
      String? thumb;
      if (await File(p.join(albumDir.path, 'thumb.jpg')).exists()) {
        thumb = p.join(albumDir.path, 'thumb.jpg');
      }
      await for (final img in _files(albumDir.path)) {
        final ext = p.extension(img.path).toLowerCase();
        if (!supportedImageExts.contains(ext)) continue;
        final stat = await img.stat();
        items.add(MediaItem(
          path: img.path,
          category: MediaCategory.images,
          type: MediaType.image,
          title: p.basenameWithoutExtension(img.path),
          albumArtPath: thumb ?? img.path,
          fileSizeBytes: stat.size.toInt(),
          modified: stat.modified,
          extension: ext,
        ));
      }
    }
    return items;
  }

  // ── SHOWS ── Series Name/Season 01/Episode 01.mkv
  Future<List<MediaItem>> _scanShows(String root) async {
    final items = <MediaItem>[];
    await for (final seriesDir in _dirs(root)) {
      final seriesName = p.basename(seriesDir.path);
      await for (final seasonDir in _dirs(seriesDir.path)) {
        final seasonName = p.basename(seasonDir.path);
        final seasonNum = _extractSeasonNumber(seasonName);
        await for (final ep in _files(seasonDir.path)) {
          final ext = p.extension(ep.path).toLowerCase();
          if (!supportedVideoExts.contains(ext)) continue;
          final epNum = _extractEpisodeNumber(p.basenameWithoutExtension(ep.path));
          final stat = await ep.stat();
          items.add(MediaItem(
            path: ep.path,
            category: MediaCategory.shows,
            type: MediaType.video,
            title: p.basenameWithoutExtension(ep.path),
            seriesName: seriesName,
            season: seasonName,
            seasonNumber: seasonNum,
            episodeNumber: epNum,
            fileSizeBytes: stat.size.toInt(),
            modified: stat.modified,
            extension: ext,
          ));
        }
      }
    }
    return items;
  }

  // ── MOVIES ── standalone file or sub-folder = film series
  Future<List<MediaItem>> _scanMovies(String root) async {
    final items = <MediaItem>[];
    await for (final entry in _entries(root)) {
      final stat = await entry.stat();
      if (stat.type == FileSystemEntityType.file) {
        final ext = p.extension(entry.path).toLowerCase();
        if (!supportedVideoExts.contains(ext)) continue;
        items.add(MediaItem(
          path: entry.path,
          category: MediaCategory.movies,
          type: MediaType.video,
          title: p.basenameWithoutExtension(entry.path),
          seriesName: null,
          fileSizeBytes: stat.size.toInt(),
          modified: stat.modified,
          extension: ext,
        ));
      } else if (stat.type == FileSystemEntityType.directory) {
        final seriesName = p.basename(entry.path);
        await for (final movie in _files(entry.path)) {
          final ext = p.extension(movie.path).toLowerCase();
          if (!supportedVideoExts.contains(ext)) continue;
          final mStat = await movie.stat();
          items.add(MediaItem(
            path: movie.path,
            category: MediaCategory.movies,
            type: MediaType.video,
            title: p.basenameWithoutExtension(movie.path),
            seriesName: seriesName,
            fileSizeBytes: mStat.size.toInt(),
            modified: mStat.modified,
            extension: ext,
          ));
        }
      }
    }
    return items;
  }

  // ── PORN ── per studio folder or flat
  Future<List<MediaItem>> _scanPorn(String root) async {
    final items = <MediaItem>[];
    await for (final entry in _entries(root)) {
      final stat = await entry.stat();
      if (stat.type == FileSystemEntityType.directory) {
        final studio = p.basename(entry.path);
        await for (final file in _files(entry.path)) {
          final ext = p.extension(file.path).toLowerCase();
          if (!supportedVideoExts.contains(ext)) continue;
          final s = await file.stat();
          items.add(MediaItem(
            path: file.path,
            category: MediaCategory.porn,
            type: MediaType.video,
            title: p.basenameWithoutExtension(file.path),
            seriesName: studio,
            fileSizeBytes: s.size.toInt(),
            modified: s.modified,
            extension: ext,
          ));
        }
      } else {
        final ext = p.extension(entry.path).toLowerCase();
        if (!supportedVideoExts.contains(ext)) continue;
        items.add(MediaItem(
          path: entry.path,
          category: MediaCategory.porn,
          type: MediaType.video,
          title: p.basenameWithoutExtension(entry.path),
          fileSizeBytes: stat.size.toInt(),
          modified: stat.modified,
          extension: ext,
        ));
      }
    }
    return items;
  }

  // ── helpers ────────────────────────────────────────────────────────────
  Stream<Directory> _dirs(String path) async* {
    await for (final e in Directory(path).list(followLinks: false).cast<Directory>()) {
      yield e;
    }
  }

  Stream<File> _files(String path) async* {
    await for (final e in Directory(path).list(followLinks: false).cast<File>()) {
      yield e;
    }
  }

  Stream<FileSystemEntity> _entries(String path) async* {
    await for (final e in Directory(path).list(followLinks: false)) {
      yield e;
    }
  }

  int? _extractSeasonNumber(String n) {
    final m = RegExp(r'(?:season|s)\s*(\d+)', caseSensitive: false).firstMatch(n);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  int? _extractEpisodeNumber(String n) {
    final m = RegExp(r'(?:episode|ep|e)\s*(\d+)', caseSensitive: false).firstMatch(n);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }
}
