import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';

class SettingsRepo {
  static const _keyMediaRoots = 'media_roots';
  static const _keyPornEnabled = 'porn_enabled';
  static const _keyTheme = 'theme_mode';

  late final Map<String, String> _envMap;

  /// Load environment overrides from a .env file if present.
  /// Called once per app session (singleton pattern via static init).
  static SettingsRepo? _instance;
  static Future<SettingsRepo> getInstance() async {
    _instance ??= await SettingsRepo._load();
    return _instance!;
  }

  SettingsRepo._(this._envMap);

  static Future<SettingsRepo> _load() async {
    final env = <String, String>{};
    final scriptDir = p.dirname(Platform.script.toFilePath());
    final envPath = p.join(scriptDir, '..', '..', '.env');
    final file = File(envPath);
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
    return SettingsRepo._(env);
  }

  /// Hardcoded personal defaults. Consumers should use .env or Settings UI instead.
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
      MediaCategory.movies:  _envMap['WATCH_MOVIES_ROOT'] ?? _homeDefaults[MediaCategory.movies]!,
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
