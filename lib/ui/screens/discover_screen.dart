import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      return await svc.search(query);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('search error: $e'), backgroundColor: Colors.red.shade900),
        );
      }
      return [];
    }
  }

  Future<List<JResult>> _fetchDiscover() async {
    final svc = ref.read(jellyseerrServiceProvider);
    if (svc.baseUrl.isEmpty) return [];
    try {
      return await svc.discover();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // The debounced search already fires on change; pressing enter
            // just finalizes the current search immediately.
            _debounce?.cancel();
            setState(() {
              _currentQuery = _ctrl.text.trim();
              _showResults = _currentQuery.isNotEmpty;
              _resultsFuture = _showResults
                  ? _fetchResults(_currentQuery)
                  : _fetchDiscover();
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
        ],
      ),
      body: FutureBuilder<List<JResult>>(
        future: _resultsFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
            // Still loading initially — show a skeleton grid
            return _buildSkeleton(cols, isMobile);
          }
          if (snap.hasError) {
            return Center(child: Text('error: ${snap.error}'));
          }
          final results = snap.data ?? [];
          if (results.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _showResults
                      ? 'no results for "$_currentQuery".\ntry again or check your jellyseerr URL in settings.'
                      : 'no content available.\nconfigure JELLYSEERR_API_URL in .env or build with --dart-define.',
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
            itemBuilder: (_, i) => _buildCard(context, results[i], cols),
          );
        },
      ),
    );
  }

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
            Expanded(
              child: Container(color: Colors.grey.shade800, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            ),
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
  @override
  Widget build(BuildContext context) {
    final isMovie = item.mediaType == 'movie';
    final subText = '${item.releaseDate ?? '?'} · ${isMovie ? 'movie' : 'tv'} · ${item.rating?.toStringAsFixed(1) ?? '?'}';
    final placeholder = _imagePlaceholder(isMovie);

    return GestureDetector(
      onTap: () {
        // Show details bottom sheet
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
    final isMovie = item.mediaType == 'movie';
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
                    Text('${item.releaseDate ?? '?'} · ${isMovie ? 'movie' : 'tv show'}',
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
              child: Text('overview', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 2)),
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
