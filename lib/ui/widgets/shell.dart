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
<<<<<<< Updated upstream
=======
  static _WatchShellState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
    startMediaWatcher(ref);
  }

  @override
  void dispose() {
    _instance = null;
    stopMediaWatcher();
    super.dispose();
  }

  // PiP state
  MediaItem? _pipItem;
  VideoPlayerController? _pipController;
  Offset _pipOffset = const Offset(16, 100);
  Size _pipSize = const Size(280, 160);

  static void _openPiP(MediaItem item, VideoPlayerController controller) {
    final state = _instance;
    if (state != null) {
      state._pipItem = item;
      state._pipController = controller;
      state.setState(() {});
    }
  }

  static void _closePiP() {
    final state = _instance;
    if (state != null) {
      state._pipController?.pause();
      state._pipItem = null;
      state._pipController = null;
      state.setState(() {});
    }
  }

>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final pornEnabled = ref.watch(pornToggleProvider);
    final items = [
<<<<<<< Updated upstream
      _NavItem(icon: Icons.home, label: 'home', path: '/'),
      _NavItem(icon: Icons.music_note, label: 'music', path: '/music'),
      _NavItem(icon: Icons.photo_library, label: 'images', path: '/images'),
      _NavItem(icon: Icons.tv, label: 'shows', path: '/shows'),
      _NavItem(icon: Icons.movie, label: 'movies', path: '/movies'),
      if (pornEnabled) _NavItem(icon: Icons.lock, label: 'adult', path: '/porn'),
      _NavItem(icon: Icons.search, label: 'search', path: '/search'),
      _NavItem(icon: Icons.settings, label: 'settings', path: '/settings'),
=======
      _NavItem(icon: Icons.home, label: '', path: '/'),
      _NavItem(icon: Icons.tv, label: '', path: '/shows'),
      _NavItem(icon: Icons.movie, label: '', path: '/movies'),
      if (pornEnabled) _NavItem(icon: Icons.lock, label: '', path: '/porn'),
      _NavItem(icon: Icons.photo_library, label: '', path: '/images'),
      _NavItem(icon: Icons.search, label: '', path: '/search'),
      _NavItem(icon: Icons.settings, label: '', path: '/settings'),
>>>>>>> Stashed changes
    ];
    final current = GoRouterState.of(context).uri.path;
    final sel = items.indexWhere((n) => n.path == current);

    if (isMobile) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: sel >= 0 ? sel : 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: items
              .map((n) => NavigationDestination(icon: Icon(n.icon), label: ''))
              .toList(),
          onDestinationSelected: (i) => context.go(items[i].path),
        ),
      );
<<<<<<< Updated upstream
=======
    } else {
      body = Scaffold(
        body: Row(children: [
          SizedBox(
            width: 64,
            child: NavigationRail(
              selectedIndex: sel >= 0 ? sel : 0,
              labelType: NavigationRailLabelType.none,
              destinations: items
                  .map((n) => NavigationRailDestination(
                      icon: Icon(n.icon, size: 20),
                      label: const Text('')))
                  .toList(),
              onDestinationSelected: (i) => context.go(items[i].path),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.child),
        ]),
      );
>>>>>>> Stashed changes
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
