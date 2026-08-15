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
    final pathPart = p.startsWith('/') ? p : '/$p';
    return '$cleanBase/img/t$pathPart';
  }
}

class JellyseerrService {
  final String baseUrl; // e.g. http://192.168.4.233:5055 or /api/jellyseerr
  String? apiKey;
  final Map<String, String> _cookies = {};

  JellyseerrService({required this.baseUrl, this.apiKey});

  Map<String, String> get _headers {
    final h = {'Accept': 'application/json'};
    if (apiKey != null && apiKey!.isNotEmpty) h['Authorization'] = 'Bearer $apiKey';
    if (_cookies.isNotEmpty) h['Cookie'] = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return h;
  }

  void _captureCookies(http.Response resp) {
    final setCookie = resp.headers['set-cookie'];
    if (setCookie == null) return;
    // Parse Set-Cookie header (may contain multiple cookies)
    for (final cookie in setCookie.split(',')) {
      final parts = cookie.trim().split(';');
      if (parts.isEmpty) continue;
      final nv = parts[0].trim().split('=');
      if (nv.length == 2) {
        final name = nv[0].trim();
        final value = nv[1].trim();
        if (name.isNotEmpty && value.isNotEmpty && !name.toLowerCase().contains('expires')) {
          _cookies[name] = value;
        }
      }
    }
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
    if (resp.statusCode == 401) return _handleUnauthorized();
    if (resp.statusCode != 200) throw Exception('jellyseerr search failed: ${resp.statusCode}');
    _captureCookies(resp);
    return _parseResults(jsonDecode(resp.body));
  }

  /// Discover popular movies + TV shows for the landing page.
  Future<List<JResult>> discover({int page = 1}) async {
    final List<JResult> results = [];
    for (final type in ['movie', 'tv']) {
      final url = _url('/api/v1/discover/${type}s?page=$page');
      try {
        final resp = await http.get(Uri.parse(url), headers: _headers);
        if (resp.statusCode == 401) return _handleUnauthorized();
        if (resp.statusCode != 200) continue;
        _captureCookies(resp);
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final raw = data['results'] as List<dynamic>? ?? [];
        for (final r in raw) {
          final m = r as Map<String, dynamic>;
          results.add(JResult.fromJson(m, type));
        }
      } catch (e) {
        debugPrint('jellyseerr discover error: $e');
      }
    }
    return results;
  }

  List<JResult> _parseResults(dynamic body) {
    if (body is Map<String, dynamic>) {
      final raw = body['results'] as List<dynamic>? ?? [];
      return raw.map((r) => JResult.fromJson(r as Map<String, dynamic>, _guessType(r))).toList();
    }
    if (body is List) {
      return body.map((r) => JResult.fromJson(r as Map<String, dynamic>, _guessType(r))).toList();
    }
    return [];
  }

  String _guessType(dynamic m) {
    final mt = m['media_type'] ?? m['type'];
    if (mt is String) return mt == 'tv' ? 'tv' : 'movie';
    return m['title'] != null ? 'movie' : 'tv';
  }

  /// Returns empty list when unauthenticated — the UI will show a login prompt.
  Future<List<JResult>> _handleUnauthorized() {
    return Future.value([]);
  }

  /// Convenience: log in to jellyseerr via email/password.
  /// Uses the jellyseerr local auth endpoint.
  Future<bool> login(String email, String password) async {
    final url = _url('/api/v1/auth/local');
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', ..._headers},
        body: jsonEncode({'email': email, 'password': password}),
      );
      _captureCookies(resp);
      // Check for JWT token in response
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = jsonDecode(resp.body);
        if (body is Map<String, dynamic> && body['token'] != null) {
          apiKey = body['token'] as String;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if currently authenticated.
  Future<bool> checkAuth() async {
    final url = _url('/api/v1/user');
    final resp = await http.get(Uri.parse(url), headers: _headers);
    _captureCookies(resp);
    return resp.statusCode == 200;
  }

  /// Convenience: create a service configured for this platform.
  static JellyseerrService forPlatform({required String? nativeUrl, required String? apiKey}) {
    if (kIsWeb) {
      return JellyseerrService(baseUrl: '/api/jellyseerr', apiKey: apiKey);
    }
    return JellyseerrService(baseUrl: nativeUrl ?? '', apiKey: apiKey);
  }

  static void debugPrint(Object? message) {
    // ignore: avoid_print
    print(message);
  }
}
