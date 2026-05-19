import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class SettingsRepo {
  static const _keyMediaRoots = 'media_roots';
  static const _keyPornEnabled = 'porn_enabled';
  static const _keyTheme = 'theme_mode';

  static String? _env(String varName, String? override) => override ?? _envFromPlatform(varName);

  static String? _envFromPlatform(String varName) {
    // Read from platform environment; null if not set
    try {
      return const String.fromEnvironment(varName);
    } catch (_) {
      return null;
    }
  }

  static String _dir(String envVar, String fallback) {
    final v = _env(envVar, null);
    return (v != null && v.isNotEmpty) ? v : fallback;
  }

  static Map<String, String> get defaultRoots => {
        MediaCategory.music:  _dir('WATCH_MUSIC_ROOT',  '/mnt/nextcloud/house/files/media/music'),
        MediaCategory.images: _dir('WATCH_IMAGES_ROOT', '/mnt/nextcloud/house/files/media/images'),
        MediaCategory.shows:  _dir('WATCH_SHOWS_ROOT',  '/mnt/nextcloud/house/files/media/shows'),
        MediaCategory.movies:  _dir('WATCH_MOVIES_ROOT', '/mnt/nextcloud/house/files/media/movies'),
        MediaCategory.porn:   _dir('WATCH_PORN_ROOT',   '/mnt/nextcloud/house/files/media/porn'),
      };

  Future<Map<String, String>> getMediaRoots() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyMediaRoots);
    if (json == null) return Map.from(defaultRoots);
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
