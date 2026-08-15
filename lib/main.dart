
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/screens/home_screen.dart';
import 'package:watch/ui/screens/music_screen.dart';
import 'package:watch/ui/screens/images_screen.dart';
import 'package:watch/ui/screens/shows_screen.dart';
import 'package:watch/ui/screens/movies_screen.dart';
import 'package:watch/ui/screens/porn_screen.dart';
import 'package:watch/ui/screens/search_screen.dart';
import 'package:watch/ui/screens/settings_screen.dart';
import 'package:watch/ui/screens/image_viewer_screen.dart';
import 'package:watch/ui/widgets/shell.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => _Root(child: HomeScreen())),
    GoRoute(path: '/music', builder: (_, __) => _Root(child: MusicScreen())),
    GoRoute(path: '/images', builder: (_, __) => _Root(child: ImagesScreen())),
    GoRoute(path: '/shows', builder: (_, __) => _Root(child: ShowsScreen())),
    GoRoute(path: '/movies', builder: (_, __) => _Root(child: MoviesScreen())),
    GoRoute(path: '/search', builder: (_, __) => _Root(child: SearchScreen())),
    GoRoute(path: '/settings', builder: (_, __) => _Root(child: SettingsScreen())),
    GoRoute(path: '/porn', builder: (_, __) => _Root(child: PornScreen())),
    GoRoute(path: '/image-viewer', builder: (_, GoRouterState st) => ImageViewerScreen(
      path: st.uri.queryParameters['path'] ?? '', title: st.uri.queryParameters['title'] ?? '',
    )),
  ],
);

class _Root extends ConsumerWidget {
  final Widget child;
  const _Root({required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WatchShell(child: child);
}

class WatchApp extends ConsumerWidget {
  const WatchApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xff6c5ce7),
        scaffoldBackgroundColor: const Color(0xff0a0a1a),
        cardColor: const Color(0xff13132a),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xff13132a), elevation: 0),
        navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xff13132a), indicatorColor: Color(0xff6c5ce7)),
        navigationRailTheme: const NavigationRailThemeData(backgroundColor: Color(0xff13132a), indicatorColor: Color(0xff6c5ce7)),
        dividerTheme: DividerThemeData(color: Colors.grey.shade800),
      ),
      themeMode: themeModeAsync.when(
        data: (m) => m == 'light' ? ThemeMode.light : m == 'dark' ? ThemeMode.dark : ThemeMode.system,
        loading: () => ThemeMode.system,
        error: (_, __) => ThemeMode.system,
      ),
      routerConfig: _router,
    );
  }
}

void main() => runApp(const ProviderScope(child: WatchApp()));
