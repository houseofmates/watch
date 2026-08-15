import 'package:shared_preferences/shared_preferences.dart';

class PlaybackStateRepo {
  static const _prefix = 'pos:';
  static const _durPrefix = 'dur:';

  static Future<void> savePosition(String filePath, int millis, {int? durationMs}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$filePath', millis);
    if (durationMs != null) {
      await prefs.setInt('$_durPrefix$filePath', durationMs);
    }
  }

  static Future<int?> getPosition(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$filePath');
  }

  static Future<int?> getDuration(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_durPrefix$filePath');
  }

  static Future<void> clearPosition(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$filePath');
    await prefs.remove('$_durPrefix$filePath');
  }

  /// Returns true if there's a saved position worth resuming (not near end)
  static Future<bool> hasResumablePosition(String filePath, {int nearEndThresholdMs = 5000}) async {
    final pos = await getPosition(filePath);
    return pos != null && pos > nearEndThresholdMs;
  }
}