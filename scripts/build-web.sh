#!/bin/bash
# Build the Flutter web app with patches for proper deployment through Cloudflare tunnel.
# Fixes: local CanvasKit loading, local font fallback, service worker disabled, anti-caching headers.
set -e
cd /home/house/projects/watch
export PATH="/home/house/flutter/bin:$PATH"

echo "Building web..."
flutter build web --release

# Patch flutter_bootstrap.js: remove service worker, use local CanvasKit + font paths
python3 -c "
import re
with open('build/web/flutter_bootstrap.js', 'r') as f:
    content = f.read()

# Replace the load() call — remove serviceWorkerSettings, add config with local URLs
old_load = r'''_flutter\.loader\.load\(\{[^}]*serviceWorkerSettings[^}]*\}\);'''
new_load = '''_flutter.loader.load({
  config: {
    canvasKitBaseUrl: \"canvaskit/\",
    fontFallbackBaseUrl: \"/assets/fonts/\",
  }
});'''
content = re.sub(old_load, new_load, content, flags=re.DOTALL)

with open('build/web/flutter_bootstrap.js', 'w') as f:
    f.write(content)
print('patched flutter_bootstrap.js')
"

# Remove service worker (not needed — causes stale cache issues through CDN)
rm -f build/web/flutter_service_worker.js build/web/flutter_service_worker.js.map
echo "removed service worker"

# Patch index.html: add anti-caching + stale SW cleanup
python3 -c "
with open('build/web/index.html', 'r') as f:
    content = f.read()

# Fix base href (build may set it to \$FLUTTER_BASE_HREF)
content = content.replace('<base href=\"\$FLUTTER_BASE_HREF\">', '<base href=\"/\">')

# Add viewport + anti-caching meta tags after description meta
content = content.replace(
    '<meta name=\"description\" content=\"A new Flutter project.\">',
    '<meta name=\"description\" content=\"watch — media server and player\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n\n  <!-- Prevent caching through Cloudflare CDN and browser cache -->\n  <meta http-equiv=\"Cache-Control\" content=\"no-cache, no-store, must-revalidate\">\n  <meta http-equiv=\"Pragma\" content=\"no-cache\">\n  <meta http-equiv=\"Expires\" content=\"0\">'
)

# Add SW cleanup script before flutter_bootstrap.js
content = content.replace(
    '<script src=\"flutter_bootstrap.js\" async></script>',
    '<!-- Force-unregister any stale service workers from previous builds -->\n  <script>\n    if (\'serviceWorker\' in navigator) {\n      navigator.serviceWorker.getRegistrations().then(function(registrations) {\n        registrations.forEach(function(reg) { reg.unregister(); });\n      });\n    }\n  </script>\n  <script src=\"flutter_bootstrap.js\" async></script>'
)

with open('build/web/index.html', 'w') as f:
    f.write(content)
print('patched index.html')
"

# Copy to releases
rm -rf releases/web
cp -r build/web releases/web
rm -f releases/web/flutter_service_worker.js releases/web/flutter_service_worker.js.map

echo "web build complete -> releases/web/"
