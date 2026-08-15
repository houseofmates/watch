import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Result from a Jellyseerr search or discovery query.
class JResult {
  final int id;
  final String mediaType; // 'movie' | 'tv'
  final String title;
  final String? posterPath; // raw poster_path from tmdb
  final String? backdropPath;
  final String overview;
  final int? releaseDate; // year as int
  final double? rating;

  JResult({
    required this.id,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    this.releaseDate,
    this.rating,
  });

  factory JResult.fromJson(Map<String, dynamic> m, String mediaTypeOverride) {
    return JResult(
      id: m['id'] as int,
      mediaType: mediaTypeOverride,
      title: (m['title'] ?? m['name'] ?? m['original_title'] ?? m['original_name'] ?? 'unknown') as String,
      posterPath: m['poster_path'] as String?,
      backdropPath: m['backdrop_path'] as String?,
      overview: (m['overview'] ?? '') as String,
      rating: (m['vote_average'] as num?)?.toDouble(),
      releaseDate: _extractYear(m['release_date'] ?? m['first_air_date']),
    );
  }

  static int? _extractYear(dynamic v) {
    if (v is String && v.length >= 4) {
      final n = int.tryParse(v.substring(0, 4));
      if (n != null) return n;
    }
    return null;
  }

  /// Full image URL — jellyseerr proxies TMDB images at /img/
  String? posterUrl(String baseUrl) {
    final p = posterPath;
    if (p == null) return null;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$cleanBase/img/t${p.startsWith('/') ? '' : '/'}${p.substring(1)}';
  }
}

class JellyseerrService {
  final String baseUrl; // e.g. http://192.168.4.233:5052 or /api/jellyseerr
  final String? apiKey;

  JellyseerrService({required this.baseUrl, this.apiKey});

  Map<String, String> get _headers {
    final h = {'Accept': 'application/json'};
    if (apiKey != null && apiKey!.isNotEmpty) h['Authorization'] = 'Bearer $apiKey';
    return h;
  }

  String _url(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$base$path';
  }

  /// Search movies + TV shows combined.
  Future<List<JResult>> search(String query, {int page = 1, int pageSize = 20}) async {
    if (query.trim().isEmpty) return discover();
    final url = _url('/api/v1/search?query=${Uri.encodeQueryComponent(query)}&page=$page&pageSize=$pageSize');
    final resp = await http.get(Uri.parse(url), headers: _headers);
    if (resp.statusCode != 200) throw Exception('jellyseerr search failed: ${resp.statusCode}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<JResult> results = [];
    final rawResults = data['results'] as List<dynamic>? ?? [];
    for (final r in rawResults) {
      final m = r as Map<String, dynamic>;
      final mt = m['media_type'] as String? ?? m['type'] as String? ?? 'movie';
      results.add(JResult.fromJson(m, mt));
    }
    return results;
  }

  /// Discover popular movies + TV shows for the landing page.
  Future<List<JResult>> discover({int page = 1}) async {
    final List<JResult> results = [];
    try {
      // Popular movies
      final mvUrl = _url('/api/v1/discover/movies?page=$page');
      final mvResp = await http.get(Uri.parse(mvUrl), headers: _headers);
      if (mvResp.statusCode == 200) {
        final data = jsonDecode(mvResp.body) as Map<String, dynamic>;
        final raw = data['results'] as List<dynamic>? ?? [];
        for (final r in raw) {
          final m = r as Map<String, dynamic>;
          results.add(JResult.fromJson(m, 'movie'));
        }
      }
    } catch (_) {}
    try {
      // Popular TV
      final tvUrl = _url('/api/v1/discover/tv?page=$page');
      final tvResp = await http.get(Uri.parse(tvUrl), headers: _headers);
      if (tvResp.statusCode == 200) {
        final data = jsonDecode(tvResp.body) as Map<String, dynamic>;
        final raw = data['results'] as List<dynamic>? ?? [];
        for (final r in raw) {
          final m = r as Map<String, dynamic>;
          results.add(JResult.fromJson(m, 'tv'));
        }
      }
    } catch (_) {}
    return results;
  }

  /// Convenience: create a service configured for this platform.
  static JellyseerrService forPlatform({required String? nativeUrl, required String? apiKey}) {
    if (kIsWeb) {
      return JellyseerrService(baseUrl: '/api/jellyseerr', apiKey: apiKey);
    }
    return JellyseerrService(baseUrl: nativeUrl ?? '', apiKey: apiKey);
  }
}
