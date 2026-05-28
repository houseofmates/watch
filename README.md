<h1 align="center">watch</h1>

<p align="center">
  <strong>media server + player</strong><br>
  flutter (3.41) app. linux desktop, android apk, web — single codebase.
</p>

<p align="center">
  <a href="#quick-start">quick start</a> •
  <a href="#features">features</a> •
  <a href="#architecture">architecture</a> •
  <a href="#customise-media-paths">customise media paths</a> •
  <a href="#notes">notes</a>
</p>

<hr>

<h2 align="center" id="quick-start">quick start</h2>

<h3 align="center" id="prerequisites">prerequisites</h3>

- flutter 3.41 sdk at `~/flutter-sdk` (exported to path)
- all media files are read directly from disk — no transcoding

<h3 align="center" id="default-media-roots">default media roots</h3>

<pre align="center"><code>/mnt/nextcloud/house/files/media/music
/mnt/nextcloud/house/files/media/images
/mnt/nextcloud/house/files/media/shows
/mnt/nextcloud/house/files/media/movies
/mnt/nextcloud/house/files/media/porn
</code></pre>

<p align="center">all paths are configurable at runtime from settings.</p>

<h3 align="center" id="build-everything">build everything</h3>

<pre align="center"><code>export PATH="$HOME/flutter-sdk/bin:$PATH"
./build.sh
</code></pre>

<p align="center">artifacts land in <code>releases/</code>:</p>

- `releases/` — linux bundle binaries
- `releases/web/` — static web build
- `releases/watch-release.apk` — signed debug apk

<h3 align="center" id="run-on-linux">run on linux</h3>

<pre align="center"><code>export PATH="$HOME/flutter-sdk/bin:$PATH"
cd watch
flutter run -d linux
</code></pre>

<h3 align="center" id="install-apk-on-android">install apk on android</h3>

<pre align="center"><code>adb install releases/watch-release.apk
# or drag-and-drop the apk into android's file manager
</code></pre>

<p align="center">the apk is signed with the default debug key.</p>

<h3 align="center" id="run-on-web">run on web</h3>

<pre align="center"><code>cd build/web
python -m http.server 8080
# open http://localhost:8080
</code></pre>

<p align="center">or deploy <code>build/web/</code> as static files to any web host / cloudflare pages / nginx.</p>

<hr>

<h2 align="center" id="features">features</h2>

<div align="center">
<table>
  <thead>
    <tr><th>tab</th><th>what it shows</th></tr>
  </thead>
  <tbody>
    <tr><td>home</td><td>category summary grid</td></tr>
    <tr><td>music</td><td>albums → tracks, album art from <code>folder.jpg</code></td></tr>
    <tr><td>images</td><td>photo albums → fullscreen viewer (swipe to flip)</td></tr>
    <tr><td>shows</td><td>series → season → episode</td></tr>
    <tr><td>movies</td><td>per-film-series grid, standalone single files</td></tr>
    <tr><td>adult</td><td>configurable — toggled off by default with lock in settings</td></tr>
    <tr><td>search</td><td>case-insensitive title search across all categories</td></tr>
    <tr><td>settings</td><td>porn toggle, light/dark/system theme, all 5 media root paths, rescan button</td></tr>
  </tbody>
</table>
</div>

<h3 align="center" id="porn-filter">porn filter</h3>

<p align="center">toggled on/off from settings. when disabled, the adult tab is removed from nav and category is excluded from scan results. the toggle is always visible in settings regardless.</p>

<h3 align="center" id="folder-conventions">folder conventions</h3>

- **music** — top-level folders = album name; album art = `folder.jpg` / `cover.png` inside each album folder
- **images** — top-level folders = album name; `thumb.jpg` as preview, else first image
- **shows** — `series name/season 01/episode 01.mkv` (regex: `s\s*\d+`, `ep\s*\d+` in filenames)
- **movies** — standalone video files at root = solo movie; sub-folders with multiple videos = film series
- **adult** — studio folders or flat files; same video format support

<h3 align="center" id="supported-formats">supported formats</h3>

<p align="center">audio <code>.mp3 .flac .wav .aac .ogg .m4a .wma .alac</code><br>
video <code>.mp4 .mkv .avi .mov .webm .flv .wmv .m4v .ts</code><br>
images <code>.jpg .jpeg .png .gif .bmp .webp .tiff .heic</code></p>

<hr>

<h2 align="center" id="architecture">architecture</h2>

<pre align="center"><code>lib/
  core/          constants, routes
  models/        mediaitem, mediagroup
  services/      mediascanner, settingsrepo, riverpod providers
  ui/
    screens/     all pages (home, music, images, shows, movies, adult,
                  search, settings, player, image-viewer)
    widgets/     mediacard grid tile, watchshell adaptive nav
  main.dart      providerscope → gorouter → materialapp
</code></pre>

<p align="center">state: <strong>riverpod 2</strong>. navigation: <strong>gorouter</strong>. audio: <strong>audioplayers 6</strong>. video: <strong>chewie</strong> on top of <strong>video_player</strong>. images: <strong>photo_view</strong>.</p>

<hr>

<h2 align="center" id="customise-media-paths">customise media paths</h2>

<p align="center">open settings → media roots → tap the folder icon on any row. pick a directory. settings are saved in sharedpreferences.</p>

<hr>

<h2 align="center" id="notes">notes</h2>

- no transcoding. files are opened as-is.
- linux desktop reads /mnt/ paths directly — no file-picker restriction on desktop; the picker falls back to a text field for custom paths.
- apk is a release-signed debug build. for production signing, add keystore config to `android/app/build.gradle`.

<hr>

<h2 align="center">license</h2>

<div align="center">
  <a href="./LICENSE">mates license</a>
</div>
