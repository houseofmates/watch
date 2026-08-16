import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';

// Dart-define overrides (compiled into APK / web via --dart-define or --dart-define-from-file)
const _dartMusicRoot  = String.fromEnvironment('WATCH_MUSIC_ROOT');
const _dartShowsRoot  = String.fromEnvironment('WATCH_SHOWS_ROOT');
const _dartMoviesRoot = String.fromEnvironment('WATCH_MOVIES_ROOT');
const _dartPornRoot   = String.fromEnvironment('WATCH_PORN_ROOT');

const _dartJellyseerrUrl = String.fromEnvironment('JELLYSEERR_API_URL');

class SettingsRepo {
  static const _keyMediaRoots   = 'media_roots';
  static const _keyPornEnabled  = 'porn_enabled';
  static const _keyTheme        = 'theme_mode';

  late final Map<String, String> _envMap;

  static SettingsRepo? _instance;
  static Future<SettingsRepo> getInstance() async {
    _instance ??= await SettingsRepo._load();
    return _instance!;
  }

  SettingsRepo._(this._envMap);

  static Future<SettingsRepo> _load() async {
    final env = <String, String>{};
    // 1. Try dart-defines (compiled into APK via --dart-define)
    if (_dartMusicRoot.isNotEmpty)  env['WATCH_MUSIC_ROOT']  = _dartMusicRoot;
    if (_dartShowsRoot.isNotEmpty)  env['WATCH_SHOWS_ROOT']  = _dartShowsRoot;
    if (_dartMoviesRoot.isNotEmpty) env['WATCH_MOVIES_ROOT'] = _dartMoviesRoot;
    if (_dartPornRoot.isNotEmpty)   env['WATCH_PORN_ROOT']   = _dartPornRoot;
    if (_dartJellyseerrUrl.isNotEmpty) env['JELLYSEERR_API_URL'] = _dartJellyseerrUrl;
    // 2. Try .env file (desktop / local dev only — not on web)
    if (env.isEmpty && !kIsWeb) {
      final scriptDir = p.dirname(Platform.script.toFilePath());
      final envPath   = p.join(scriptDir, '..', '..', '.env');
      final file      = File(envPath);
      if (file.existsSync()) {
        try {
          for (final line in file.readAsLinesSync()) {
            final t = line.trim();
            if (t.isEmpty || t.startsWith('#')) continue;
            final eq = t.indexOf('=');
            if (eq > 0) {
              final key = t.substring(0, eq).trim();
              final val = t.substring(eq + 1).trim();
              if (key.isNotEmpty) env[key] = val;
            }
          }
        } catch (_) { /* ignore bad env file */ }
      }
    }
    return SettingsRepo._(env);
  }

  /// Hardcoded personal defaults. Consumers should use .env or .dart-define instead.
  static Map<String, String> get _homeDefaults => {
        MediaCategory.music:  '/mnt/nextcloud/house/files/media/music',
        MediaCategory.images: '/mnt/nextcloud/house/files/media/images',
        MediaCategory.shows:  '/mnt/nextcloud/house/files/media/shows',
        MediaCategory.movies:  '/mnt/nextcloud/house/files/media/movies',
        MediaCategory.porn:   '/mnt/nextcloud/house/files/media/porn',
      };

  Map<String, String> get _defaultRoots {
    return {
      MediaCategory.music:  _envMap['WATCH_MUSIC_ROOT']  ?? _homeDefaults[MediaCategory.music]!,
      MediaCategory.images: _envMap['WATCH_IMAGES_ROOT'] ?? _homeDefaults[MediaCategory.images]!,
      MediaCategory.shows:  _envMap['WATCH_SHOWS_ROOT']  ?? _homeDefaults[MediaCategory.shows]!,
      MediaCategory.movies: _envMap['WATCH_MOVIES_ROOT'] ?? _homeDefaults[MediaCategory.movies]!,
      MediaCategory.porn:   _envMap['WATCH_PORN_ROOT']   ?? _homeDefaults[MediaCategory.porn]!,
    };
  }

  Future<Map<String, String>> getMediaRoots() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyMediaRoots);
    if (json == null) return Map.from(_defaultRoots);
    final Map<String, dynamic> raw = jsonDecode(json);
    return raw.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> setMediaRoots(Map<String, String> roots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMediaRoots, jsonEncode(roots));
  }

  Future<void> setMediaRoot(String category, String path) async {
    final roots = await getMediaRoots();
    roots[category] = path;
    await setMediaRoots(roots);
  }

  Future<bool> getPornEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPornEnabled) ?? true;
  }

  Future<void> setPornEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPornEnabled, enabled);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, mode);
  }
}
