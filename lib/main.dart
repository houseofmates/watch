import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/services/providers.dart';
import 'package:watch/ui/screens/home_screen.dart';
import 'package:watch/ui/screens/discover_screen.dart';
import 'package:watch/ui/screens/music_screen.dart';
import 'package:watch/ui/screens/shows_screen.dart';
import 'package:watch/ui/screens/movies_screen.dart';
import 'package:watch/ui/screens/porn_screen.dart';
import 'package:watch/ui/screens/search_screen.dart';
import 'package:watch/ui/screens/settings_screen.dart';
import 'package:watch/ui/widgets/shell.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => _Root(child: HomeScreen())),
    GoRoute(path: '/discover', builder: (_, __) => _Root(child: DiscoverScreen())),
    GoRoute(path: '/music', builder: (_, __) => _Root(child: MusicScreen())),
    GoRoute(path: '/shows', builder: (_, __) => _Root(child: ShowsScreen())),
    GoRoute(path: '/movies', builder: (_, __) => _Root(child: MoviesScreen())),
    GoRoute(path: '/search', builder: (_, __) => _Root(child: SearchScreen())),
    GoRoute(path: '/settings', builder: (_, __) => _Root(child: SettingsScreen())),
    GoRoute(path: '/search', builder: (_, __) => _Root(child: SearchScreen())),
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
        fontFamily: 'VarelaRound',
        colorScheme: ColorScheme.dark(
          primary: const Color(0xffffaf00),
          secondary: const Color(0xff3c9fdd),
          surface: const Color(0xff050505),
          onSurface: const Color(0xffe0e0e0),
          onPrimary: const Color(0xff050505),
        ),
        scaffoldBackgroundColor: const Color(0xff050505),
        cardColor: const Color(0xff0a0a0a),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff050505),
          foregroundColor: Color(0xffffaf00),
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xff050505),
          indicatorColor: Color(0xffffaf00),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xff050505),
          indicatorColor: Color(0xffffaf00),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xff1a1a1a)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xffe0e0e0)),
          bodyMedium: TextStyle(color: Color(0xffe0e0e0)),
          bodySmall: TextStyle(color: Color(0xffa0a0a0)),
        ),
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
