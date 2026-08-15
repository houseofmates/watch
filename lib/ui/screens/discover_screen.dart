import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:watch/services/jellyseerr_service.dart';
import 'package:watch/services/providers.dart';

/// Discover page with live-updating search.
///
/// As the user types, results update in real time (300ms debounce) by
/// querying the Jellyseerr API. When the search box is empty, popular
/// / trending content is shown instead.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _currentQuery = '';
  bool _showResults = false;
  bool _authFailed = false;
  late Future<List<JResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetchDiscover();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// Debounced search — fires 300ms after the user stops typing.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _currentQuery = value;
        _showResults = value.isNotEmpty;
        _resultsFuture = value.trim().isEmpty
            ? _fetchDiscover()
            : _fetchResults(value.trim());
      });
    });
  }

  Future<List<JResult>> _fetchResults(String query) async {
    final svc = ref.read(jellyseerrServiceProvider);
    if (svc.baseUrl.isEmpty) return [];
    try {
      final results = await svc.search(query);
      setState(() => _authFailed = false);
      return results;
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403')) {
        setState(() => _authFailed = true);
      }
      return [];
    }
  }

  Future<List<JResult>> _fetchDiscover() async {
    final svc = ref.read(jellyseerrServiceProvider);
    if (svc.baseUrl.isEmpty) return [];
    try {
      final results = await svc.discover();
      if (results.isEmpty) setState(() => _authFailed = true);
      return results;
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403')) {
        setState(() => _authFailed = true);
      }
      return [];
    }
  }

  void _retry() {
    setState(() {
      _authFailed = false;
      _resultsFuture = _showResults ? _fetchResults(_currentQuery) : _fetchDiscover();
    });
  }

  Future<void> _openJellyseerr() async {
    final svc = ref.read(jellyseerrServiceProvider);
    final url = svc.baseUrl;
    if (url.isEmpty) return;
    final uri = kIsWeb ? Uri.base.resolve(url) : Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cannot open $url'), backgroundColor: Colors.red.shade900),
      );
    }
  }

  Future<void> _showLoginDialog() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('jellyseerr login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(hintText: 'email', isDense: true),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(hintText: 'password', isDense: true),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final svc = ref.read(jellyseerrServiceProvider);
              final ok = await svc.login(emailCtrl.text.trim(), passCtrl.text);
              if (ok) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('logged in'), backgroundColor: Colors.green),
                  );
                }
                _retry();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('login failed'), backgroundColor: Colors.red.shade900),
                  );
                }
              }
            },
            child: const Text('login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jellyUrl = ref.watch(jellyseerrApiUrlProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cols = isMobile ? 2 : 3;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: 'search movies & shows...',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            isDense: true,
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: _onSearchChanged,
          onSubmitted: (_) {
            _debounce?.cancel();
            setState(() {
              _currentQuery = _ctrl.text.trim();
              _showResults = _currentQuery.isNotEmpty;
              _resultsFuture = _showResults ? _fetchResults(_currentQuery) : _fetchDiscover();
            });
          },
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                _onSearchChanged('');
              },
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _retry),
        ],
      ),
      body: _buildBody(jellyUrl, cols, isMobile),
    );
  }

  Widget _buildBody(String jellyUrl, int cols, bool isMobile) {
    if (jellyUrl.isEmpty) {
      return _buildNotConfigured();
    }
    if (_authFailed) {
      return _buildAuthError();
    }
    return FutureBuilder<List<JResult>>(
      future: _resultsFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
          return _buildSkeleton(cols, isMobile);
        }
        if (snap.hasError) {
          return Center(child: Text('error: ${snap.error}'));
        }
        final results = snap.data ?? [];
        if (results.isEmpty) {
          if (_authFailed) return _buildAuthError();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _currentQuery.isNotEmpty
                    ? 'no results for "$_currentQuery".\nthe jellyseerr server might not be set up yet.'
                    : 'no content available.\nconfigure jellyseerr and add media to your jellyfin library.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: isMobile ? 0.65 : 0.7,
          ),
          itemCount: results.length,
          itemBuilder: (_, i) => _buildCard(context, results[i]),
        );
      },
    );
  }

  Widget _buildNotConfigured() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('jellyseerr not configured', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('set JELLYSEERR_API_URL in .env or build with --dart-define.',
                  style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _buildAuthError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('authentication required', style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('log in to jellyseerr to access discover & search.',
                  style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('login'),
                    onPressed: _showLoginDialog,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('open jellyseerr'),
                    onPressed: _openJellyseerr,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSkeleton(int cols, bool isMobile) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: isMobile ? 0.65 : 0.7,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Container(color: Colors.grey.shade800, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12, width: double.infinity, child: ColoredBox(color: Colors.grey)),
                  SizedBox(height: 8),
                  SizedBox(height: 12, width: 100, child: ColoredBox(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, JResult item) {
    final posterUrl = item.posterUrl(ref.watch(jellyseerrApiUrlProvider));
    final isMovie = item.mediaType == 'movie';
    final subText = '${item.releaseDate ?? '?'} · ${isMovie ? 'movie' : 'tv'} · ${item.rating?.toStringAsFixed(1) ?? '?'}';
    final placeholder = _imagePlaceholder(isMovie);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).cardColor,
          builder: (_) => _DetailSheet(item: item, posterUrl: posterUrl),
        );
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: posterUrl != null
                  ? (kIsWeb
                      ? Image.network(posterUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => placeholder)
                      : Image.file(File(posterUrl), fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => placeholder))
                  : placeholder,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subText, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(bool isMovie) => ColoredBox(
        color: const Color(0xff1a1a3a),
        child: Center(child: Icon(isMovie ? Icons.movie : Icons.tv, size: 44, color: Colors.grey.shade600)),
      );
}

class _DetailSheet extends StatelessWidget {
  final JResult item;
  final String? posterUrl;
  const _DetailSheet({required this.item, required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(color: Colors.grey.shade800, child: const Center(child: Icon(Icons.movie, size: 48)));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 40,
                height: 4,
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: posterUrl != null
                        ? (kIsWeb
                            ? Image.network(posterUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
                            : Image.file(File(posterUrl!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder))
                        : placeholder,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${item.releaseDate ?? '?'} · ${item.mediaType == 'movie' ? 'movie' : 'tv show'}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    if (item.rating != null)
                      Row(children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(item.rating!.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                      ]),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(item.overview.isNotEmpty ? item.overview : 'no overview available.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
