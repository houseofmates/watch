import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/media_item.dart';
import '../services/media_scanner.dart';
import '../services/settings_repo.dart';

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

final allMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
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
      final firstSeason = e.value.values.first;
      return MediaGroup(
        name: e.key,
        category: category,
        coverArtPath: firstSeason.isNotEmpty ? firstSeason.first.path : null,
        items: firstSeason,
      );
    }).toList();
  }
  if (category == MediaCategory.movies) {
    final m = <String?, List<MediaItem>>{};
    for (final item in items.where((i) => i.category == category)) {
      m.putIfAbsent(item.seriesName, () => []).add(item);
    }
    return m.entries.map((e) => MediaGroup(
          name: e.key ?? 'Standalone',
          category: category,
          coverArtPath: e.value.isNotEmpty ? e.value.first.path : null,
          items: e.value,
        )).toList();
  }
  if (category == MediaCategory.music) {
    final m = <String?, List<MediaItem>>{};
    for (final item in items.where((i) => i.category == category)) {
      m.putIfAbsent(item.seriesName, () => []).add(item);
    }
    return m.entries.map((e) => MediaGroup(
          name: e.key ?? 'Unknown Album',
          category: category,
          coverArtPath: e.value.isNotEmpty ? e.value.first.albumArtPath : null,
          items: e.value,
        )).toList();
  }
  if (category == MediaCategory.images) {
    final m = <String, List<MediaItem>>{};
    for (final item in items.where((i) => i.category == category)) {
      final album = item.seriesName ?? 'Unknown';
      m.putIfAbsent(album, () => []).add(item);
    }
    return m.entries.map((e) {
      final first = e.value.first;
      return MediaGroup(
        name: e.key,
        category: category,
        coverArtPath: first.albumArtPath,
        items: e.value,
      );
    }).toList();
  }
  final m = <String?, List<MediaItem>>{};
  for (final item in items.where((i) => i.category == category)) {
    m.putIfAbsent(item.seriesName, () => []).add(item);
  }
  return m.entries.map((e) => MediaGroup(
        name: e.key ?? 'Unknown',
        category: category,
        coverArtPath: null,
        items: e.value,
      )).toList();
}
