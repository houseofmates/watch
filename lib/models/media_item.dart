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
  });

  factory MediaItem.dirInfo({required String path, required String category, required String title, String? seriesName, String? season, int? seasonNumber}) =>
      MediaItem(
        path: path, category: category,
        type: category == MediaCategory.images ? MediaType.image : MediaType.video,
        title: title, seriesName: seriesName, season: season, seasonNumber: seasonNumber,
        fileSizeBytes: 0, modified: DateTime(0), extension: '',
      );

  Map<String, dynamic> toMap() => {'path': path, 'category': category, 'type': type, 'title': title,
    'seriesName': seriesName ?? '', 'season': season ?? '', 'seasonNumber': seasonNumber ?? -1,
    'episodeNumber': episodeNumber ?? -1, 'albumArtPath': albumArtPath ?? '',
    'fileSizeBytes': fileSizeBytes, 'modified': modified.toIso8601String(), 'extension': extension};

  static MediaItem fromMap(Map<String, dynamic> m) => MediaItem(
    path: m['path'] as String, category: m['category'] as String, type: m['type'] as String,
    title: m['title'] as String,
    seriesName: (m['seriesName'] as String).isNotEmpty ? m['seriesName'] as String : null,
    season: (m['season'] as String).isNotEmpty ? m['season'] as String : null,
    seasonNumber: (m['seasonNumber'] as int) >= 0 ? m['seasonNumber'] as int : null,
    episodeNumber: (m['episodeNumber'] as int) >= 0 ? m['episodeNumber'] as int : null,
    albumArtPath: (m['albumArtPath'] as String).isNotEmpty ? m['albumArtPath'] as String : null,
    fileSizeBytes: m['fileSizeBytes'] as int, modified: DateTime.parse(m['modified'] as String), extension: m['extension'] as String,
  );
}

class MediaGroup {
  final String name;
  final String category;
  final String? coverArtPath;
  final List<MediaItem> items;
  MediaGroup({required this.name, required this.category, this.coverArtPath, required this.items});
  int get itemCount => items.length;
}
