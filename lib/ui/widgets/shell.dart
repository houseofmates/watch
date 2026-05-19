import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watch/services/providers.dart';

class WatchShell extends ConsumerStatefulWidget {
  final Widget child;
  const WatchShell({super.key, required this.child});
  @override
  ConsumerState<WatchShell> createState() => _WatchShellState();
}

class _WatchShellState extends ConsumerState<WatchShell> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final pornEnabled = ref.watch(pornToggleProvider);
    final items = [
      _NavItem(icon: Icons.home, label: 'home', path: '/'),
      _NavItem(icon: Icons.music_note, label: 'music', path: '/music'),
      _NavItem(icon: Icons.photo_library, label: 'images', path: '/images'),
      _NavItem(icon: Icons.tv, label: 'shows', path: '/shows'),
      _NavItem(icon: Icons.movie, label: 'movies', path: '/movies'),
      if (pornEnabled) _NavItem(icon: Icons.lock, label: 'adult', path: '/porn'),
      _NavItem(icon: Icons.search, label: 'search', path: '/search'),
      _NavItem(icon: Icons.settings, label: 'settings', path: '/settings'),
    ];
    final current = GoRouterState.of(context).uri.path;
    final sel = items.indexWhere((n) => n.path == current);

    if (isMobile) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: sel >= 0 ? sel : 0,
          destinations: items
              .map((n) => NavigationDestination(icon: Icon(n.icon), label: n.label))
              .toList(),
          onDestinationSelected: (i) => context.go(items[i].path),
        ),
      );
    }
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          selectedIndex: sel >= 0 ? sel : 0,
          labelType: NavigationRailLabelType.all,
          destinations: items
              .map((n) => NavigationRailDestination(icon: Icon(n.icon), label: Text(n.label)))
              .toList(),
          onDestinationSelected: (i) => context.go(items[i].path),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: widget.child),
      ]),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
