# watch — media server + player

Flutter (3.41) app. Linux desktop, Android APK, Web — single codebase.

## Quick start

### Prerequisites

- Flutter 3.41 SDK at `~/flutter-sdk` (exported to PATH)
- All media files are read directly from disk — no transcoding

### Default media roots

```
/mnt/nextcloud/house/files/media/music
/mnt/nextcloud/house/files/media/images
/mnt/nextcloud/house/files/media/shows
/mnt/nextcloud/house/files/media/movies
/mnt/nextcloud/house/files/media/porn
```

All paths are configurable at runtime from Settings.

### Build everything

```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"
./build.sh
```

Artifacts land in `releases/`:
- `releases/` — Linux bundle binaries
- `releases/web/` — static web build
- `releases/watch-release.apk` — signed debug APK

### Run on Linux

```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"
cd watch
flutter run -d linux
```

### Install APK on Android

```bash
adb install releases/watch-release.apk
# or drag-and-drop the APK into Android's file manager
```

The APK is signed with the default debug key.

### Run on Web

```bash
cd build/web
python -m http.server 8080
# open http://localhost:8080
```

Or deploy `build/web/` as static files to any web host / Cloudflare Pages / Nginx.

## Features

| Tab | What it shows |
|-----|--------------|
| Home | Category summary grid |
| Music | Albums → tracks, album art from `folder.jpg` |
| Images | Photo albums → fullscreen viewer (swipe to flip) |
| Shows | Series → Season → Episode |
| movies | Per-film-series grid, standalone single files |
| Adult | Configurable — toggled off by default with lock in Settings |
| Search | Case-insensitive title search across all categories |
| Settings | Porn toggle, light/dark/system theme, all 5 media root paths, rescan button |

### porn filter

Toggled on/off from Settings. When disabled, the Adult tab is removed from nav
and category is excluded from scan results. The toggle is always visible in
Settings regardless.

### folder conventions

- **Music** — top-level folders = album name; album art = `folder.jpg` /
  `cover.png` inside each album folder
- **Images** — top-level folders = album name; `thumb.jpg` as preview, else
  first image
- **Shows** — `Series Name/Season 01/Episode 01.mkv` (regex: `s\s*\d+`,
  `ep\s*\d+` in filenames)
- **Movies** — standalone video files at root = solo movie; sub-folders with
  multiple videos = film series
- **Adult** — studio folders or flat files; same video format support


### supported formats

audio `.mp3 .flac .wav .aac .ogg .m4a .wma .alac`
video `.mp4 .mkv .avi .mov .webm .flv .wmv .m4v .ts`
images `.jpg .jpeg .png .gif .bmp .webp .tiff .heic`

## Architecture

```
lib/
  core/          constants, routes
  models/        MediaItem, MediaGroup
  services/      MediaScanner, SettingsRepo, Riverpod providers
  ui/
    screens/     all pages (home, music, images, shows, movies, adult,
                  search, settings, player, image-viewer)
    widgets/     MediaCard grid tile, WatchShell adaptive nav
  main.dart      ProviderScope → GoRouter → MaterialApp
```

State: **Riverpod 2**. Navigation: **GoRouter**. Audio: **audioplayers 6**.
Video: **chewie** on top of **video_player**. Images: **photo_view**.

## Customise media paths

Open Settings → Media Roots → tap the folder icon on any row. Pick a
directory. Settings are saved in SharedPreferences.

## Notes

- No transcoding. Files are opened as-is.
- Linux desktop reads /mnt/ paths directly — no file-picker restriction on
  desktop; the picker falls back to a text field for custom paths.
- APK is a release-signed debug build. For production signing, add keystore
  config to `android/app/build.gradle`.
