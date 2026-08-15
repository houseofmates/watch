import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';

const _dartMusicRoot = String.fromEnvironment('WATCH_MUSIC_ROOT');
const _dartImagesRoot = String.fromEnvironment('WATCH_IMAGES_ROOT');
const _dartShowsRoot = String.fromEnvironment('WATCH_SHOWS_ROOT');
const _dartMoviesRoot = String.fromEnvironment('WATCH_MOVIES_ROOT');
const _dartPornRoot = String.fromEnvironment('WATCH_PORN_ROOT');

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
<<<<<<< Updated upstream
    final scriptDir = p.dirname(Platform.script.toFilePath());
    final envPath = p.join(scriptDir, '..', '..', '.env');
    final file = File(envPath);
    if (file.existsSync()) {
=======
    // 1. try dart-defines (compiled into APK via --dart-define)
    if (_dartMusicRoot.isNotEmpty) env['WATCH_MUSIC_ROOT'] = _dartMusicRoot;
    if (_dartImagesRoot.isNotEmpty) env['WATCH_IMAGES_ROOT'] = _dartImagesRoot;
    if (_dartShowsRoot.isNotEmpty) env['WATCH_SHOWS_ROOT'] = _dartShowsRoot;
    if (_dartMoviesRoot.isNotEmpty) env['WATCH_MOVIES_ROOT'] = _dartMoviesRoot;
    if (_dartPornRoot.isNotEmpty) env['WATCH_PORN_ROOT'] = _dartPornRoot;
    // 2. try .env file (desktop / local dev)
    if (env.isEmpty && !kIsWeb) {
>>>>>>> Stashed changes
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
