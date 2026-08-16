import 'package:watch/core/constants.dart';

class MediaItem {
  final String path;
  final String category;
  final String type;
  final String title;
  final String? seriesName;
  final String? season;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? albumArtPath;
  final int fileSizeBytes;
  final DateTime modified;
  final String extension;
  final int? durationSeconds;
  final String? thumbnailPath;
  final String? subtitle;

  MediaItem({
    required this.path,
    required this.category,
    required this.type,
    required this.title,
    this.seriesName,
    this.season,
    this.seasonNumber,
    this.episodeNumber,
    this.albumArtPath,
    required this.fileSizeBytes,
    required this.modified,
    required this.extension,
    this.durationSeconds,
    this.thumbnailPath,
    this.subtitle,
  });

  factory MediaItem.dirInfo({required String path, required String category, required String title, String? seriesName, String? season, int? seasonNumber}) =>
      MediaItem(
        path: path, category: category,
        type: MediaType.video,
        title: title, seriesName: seriesName, season: season, seasonNumber: seasonNumber,
        fileSizeBytes: 0, modified: DateTime(0), extension: '',
      );

  static String? _strOrNull(dynamic v) {
    if (v is String) return v.isNotEmpty ? v : null;
    return null;
  }

  static int? _intOrNull(dynamic v) {
    if (v is int) return v >= 0 ? v : null;
    return null;
  }

  Map<String, dynamic> toMap() => {'path': path, 'category': category, 'type': type, 'title': title,
    'seriesName': seriesName ?? '', 'season': season ?? '', 'seasonNumber': seasonNumber ?? -1,
    'episodeNumber': episodeNumber ?? -1, 'albumArtPath': albumArtPath ?? '',
    'fileSizeBytes': fileSizeBytes, 'modified': modified.toIso8601String(), 'extension': extension,
    'durationSeconds': durationSeconds ?? -1, 'thumbnailPath': thumbnailPath ?? '',
    'subtitle': subtitle ?? '',
  };

  static MediaItem fromMap(Map<String, dynamic> m) => MediaItem(
    path: m['path'] as String,
    category: m['category'] as String,
    type: m['type'] as String,
    title: m['title'] as String,
    seriesName: _strOrNull(m['seriesName']),
    season: _strOrNull(m['season']),
    seasonNumber: _intOrNull(m['seasonNumber']),
    episodeNumber: _intOrNull(m['episodeNumber']),
    albumArtPath: _strOrNull(m['albumArtPath']),
    fileSizeBytes: m['fileSizeBytes'] as int? ?? 0,
    modified: DateTime.parse((m['modified'] as String? ?? DateTime(0).toIso8601String())),
    extension: m['extension'] as String? ?? '',
    durationSeconds: _intOrNull(m['durationSeconds']),
    thumbnailPath: _strOrNull(m['thumbnailPath']),
    subtitle: _strOrNull(m['subtitle']),
  );

  /// For web scanning: build from the JSON returned by the watch server /api/media-list
  factory MediaItem.fromJson(Map<String, dynamic> m) {
    DateTime parseModified(dynamic v) {
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      if (v is double) return DateTime.fromMillisecondsSinceEpoch((v * 1000).round());
      if (v is String) return DateTime.parse(v);
      return DateTime(0);
    }

    return MediaItem(
      path: m['path'] as String,
      category: m['category'] as String,
      type: m['type'] as String,
      title: m['title'] as String,
      seriesName: m['seriesName'] as String?,
      season: m['season'] as String?,
      fileSizeBytes: m['fileSizeBytes'] as int? ?? 0,
      modified: parseModified(m['modified']),
      extension: m['extension'] as String? ?? '',
      durationSeconds: m['durationSeconds'] as int?,
      thumbnailPath: m['thumbnailPath'] as String?,
      subtitle: m['subtitle'] as String?,
    );
  }
}

class MediaGroup {
  final String name;
  final String category;
  final String? coverArtPath;
  final List<MediaItem> items;
  MediaGroup({required this.name, required this.category, this.coverArtPath, required this.items});
  int get itemCount => items.length;
}
