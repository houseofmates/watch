import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/media_item.dart';
import '../services/media_scanner.dart';
import '../services/settings_repo.dart';
import '../services/jellyseerr_service.dart';

final themeModeProvider = FutureProvider<String>((ref) async {
  return await (await SettingsRepo.getInstance()).getThemeMode();
});

final pornToggleProvider = StateNotifierProvider<PornToggleNotifier, bool>((ref) {
  return PornToggleNotifier();
});

class PornToggleNotifier extends StateNotifier<bool> {
  PornToggleNotifier() : super(true);
  Future<void> toggle(bool value) async {
    state = value;
    await (await SettingsRepo.getInstance()).setPornEnabled(value);
  }
}

final mediaRootsProvider = FutureProvider<Map<String, String>>((ref) async {
  return await (await SettingsRepo.getInstance()).getMediaRoots();
});

/// Tracks the last-modified timestamp of media files so the UI can refresh.
final mediaMtimeProvider = StateProvider<double>((ref) => 0.0);

final allMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
  ref.watch(mediaMtimeProvider);
  final roots = await ref.watch(mediaRootsProvider.future);
  final pornEnabled = ref.watch(pornToggleProvider);
  if (roots.isEmpty) return [];
  final scanner = MediaScanner(mediaRoots: roots, pornEnabled: pornEnabled);
  return await scanner.scanAll();
});

final categoryProvider = StateProvider<String>((ref) => MediaCategory.all);

final filteredMediaProvider = Provider<AsyncValue<List<MediaItem>>>((ref) {
  final cat = ref.watch(categoryProvider);
  final all = ref.watch(allMediaProvider);
  return all.whenData((items) {
    if (cat == MediaCategory.all) return items;
    return items.where((m) => m.category == cat).toList();
  });
});

/// Dart-define overrides for jellyseerr (used on native platforms).
const _dartJellyseerrUrl  = String.fromEnvironment('JELLYSEERR_API_URL');
const _dartJellyseerrKey = String.fromEnvironment('JELLYSEERR_API_KEY');

/// Jellyseerr API base URL — on web we proxy through the local watch server,
/// on native we connect directly to the configured instance.
final jellyseerrApiUrlProvider = Provider<String>((ref) {
  if (kIsWeb) return '/api/jellyseerr';
  return _dartJellyseerrUrl;
});

final jellyseerrApiKeyProvider = Provider<String>((ref) => _dartJellyseerrKey);

/// A configured JellyseerrService for the current platform.
final jellyseerrServiceProvider = Provider<JellyseerrService>((ref) {
  return JellyseerrService.forPlatform(
    nativeUrl: ref.watch(jellyseerrApiUrlProvider),
    apiKey: ref.watch(jellyseerrApiKeyProvider),
  );
});

/// Start polling /api/media-mtime on web (called once at app startup).
Timer? _mtimePoller;
void startMediaWatcher(WidgetRef ref) {
  if (!kIsWeb || _mtimePoller != null) return;
  _mtimePoller = Timer.periodic(const Duration(seconds: 15), (_) async {
    try {
      final res = await http.get(Uri.parse('/api/media-mtime'));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final mtime = (data['mtime'] as num).toDouble();
      if (mtime > ref.read(mediaMtimeProvider)) {
        ref.read(mediaMtimeProvider.notifier).state = mtime;
      }
    } catch (_) {}
  });
}

void stopMediaWatcher() {
  _mtimePoller?.cancel();
  _mtimePoller = null;
}

List<MediaGroup> groupMedia(List<MediaItem> items, String category) {
  if (category == MediaCategory.shows) {
    final m = <String, Map<String, List<MediaItem>>>{};
    for (final item in items.where((i) => i.category == category)) {
      final s = item.seriesName ?? 'Unknown';
      final ss = item.season ?? 'Unknown';
      m.putIfAbsent(s, () => {});
      m[s]!.putIfAbsent(ss, () => []).add(item);
    }
    return m.entries.map((e) {
      final allSeasons = e.value.values;
      final firstSeason = allSeasons.first;
      // Count real season folders (exclude 'Unknown' which is the flat-directory bucket)
      final realSeasonKeys = e.value.keys.where((k) => k != 'Unknown');
      final hasSeasonFolders = realSeasonKeys.isNotEmpty;
      final seasonCount = hasSeasonFolders ? realSeasonKeys.length : null;
      // Include ALL items (all seasons) so the detail page can show every season
      final allItems = allSeasons.expand((s) => s).toList();
      final totalEpisodes = allItems.length;
      return MediaGroup(
        name: e.key,
        category: category,
        coverArtPath: firstSeason.isNotEmpty ? firstSeason.first.thumbnailPath : null,
        items: allItems,
        seasonCount: seasonCount,
        episodeCount: totalEpisodes,
      );
    }).toList();
  }
  if (category == MediaCategory.movies) {
    final m = <String?, List<MediaItem>>{};
    for (final item in items.where((i) => i.category == category)) {
      m.putIfAbsent(item.seriesName, () => []).add(item);
    }
    final groups = <MediaGroup>[];
    for (final e in m.entries) {
      if (e.key == null) {
        // Standalone movies — each file is its own card on the home screen
        for (final item in e.value) {
          groups.add(MediaGroup(
            name: item.title,
            category: category,
            coverArtPath: item.thumbnailPath,
            items: [item],
          ));
        }
      } else {
        // Movies in subdirectories — group by dir name
        groups.add(MediaGroup(
          name: e.key!,
          category: category,
          coverArtPath: e.value.first.thumbnailPath,
          items: e.value,
        ));
      }
    }
    return groups;
  }
  // Default: porn (and any other flat category)
  final m = <String?, List<MediaItem>>{};
  for (final item in items.where((i) => i.category == category)) {
    m.putIfAbsent(item.seriesName, () => []).add(item);
  }
  final groups = <MediaGroup>[];
  for (final e in m.entries) {
    if (e.key == null) {
      // Standalone files — each file is its own card
      for (final item in e.value) {
        groups.add(MediaGroup(
          name: item.title,
          category: category,
          coverArtPath: item.thumbnailPath,
          items: [item],
        ));
      }
    } else {
      // Files in subdirectories — group by dir name (studio, etc.)
      groups.add(MediaGroup(
        name: e.key!,
        category: category,
        coverArtPath: e.value.first.thumbnailPath,
        items: e.value,
      ));
    }
  }
  return groups;
}
