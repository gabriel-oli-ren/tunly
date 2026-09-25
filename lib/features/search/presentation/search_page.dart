import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../music/data/music_providers.dart';
import '../../music/presentation/track_widgets.dart';
import '../../player/presentation/now_playing_sheet.dart';
import '../../library/data/library_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({this.initialQuery, super.key});
  final String? initialQuery;
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _controller.text = initialQuery;
      _searchTerm = initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && initialQuery.length >= 2) _startSearch(initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _searchTerm = value.trim());
    });
  }

  Future<void> _startSearch(String value) async {
    final query = value.trim();
    _debounce?.cancel();
    setState(() => _searchTerm = query);
    if (query.length < 2) return;
    await ref.read(localLibraryProvider).rememberSearch(query);
    ref.invalidate(recentSearchesProvider);
  }

  Future<void> _choose(String value) async {
    _controller.text = value;
    _startSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    final recents =
        ref.watch(recentSearchesProvider).valueOrNull ?? const <String>[];
    final hasQuery = _controller.text.trim().isNotEmpty;
    final results = _searchTerm.length >= 2
        ? ref.watch(searchResultsProvider(_searchTerm))
        : null;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Search'),
          border: null,
          transitionBetweenRoutes: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 210),
          sliver: SliverList.list(
            children: [
              CupertinoSearchTextField(
                controller: _controller,
                placeholder: 'Songs, artists, albums',
                backgroundColor: TunlyTheme.surface,
                borderRadius: BorderRadius.circular(14),
                onChanged: _onChanged,
                onSubmitted: _startSearch,
                onSuffixTap: () {
                  _controller.clear();
                  _onChanged('');
                  setState(() => _searchTerm = '');
                },
              ),
              const SizedBox(height: 26),
              if (hasQuery) ...[
                Text(
                  _searchTerm.isEmpty ? 'Searching…' : 'Results',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                if (_searchTerm.length < 2)
                  const Text(
                    'Keep typing to find songs and artists.',
                    style: TextStyle(
                      color: TunlyTheme.secondaryText,
                      fontSize: 14,
                    ),
                  )
                else
                  results!.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: CupertinoActivityIndicator(),
                    ),
                    error: (error, stack) => const Text(
                      'Search is taking a moment. Please try again.',
                      style: TextStyle(color: TunlyTheme.secondaryText),
                    ),
                    data: (tracks) => tracks.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No matches yet. Try another search.',
                              style: TextStyle(color: TunlyTheme.secondaryText),
                            ),
                          )
                        : Column(
                            children: tracks
                                .map(
                                  (track) => TrackRow(
                                    track: track,
                                    onTap: () => presentTrackPlayer(
                                      context,
                                      track,
                                      queue: tracks,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                if (recents.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Recent searches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  ...recents.map(
                    (item) =>
                        _RecentSearch(value: item, onTap: () => _choose(item)),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Browse by mood',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 13),
                _GenreGrid(onTap: _choose),
              ] else ...[
                if (recents.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent searches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          await ref.read(localLibraryProvider).clearSearches();
                          ref.invalidate(recentSearchesProvider);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  ...recents.map(
                    (item) =>
                        _RecentSearch(value: item, onTap: () => _choose(item)),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Browse all',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                _GenreGrid(onTap: _choose),
              ],
              const SizedBox(height: 22),
              const Text(
                'Music listings and promotional artwork are provided courtesy of iTunes.',
                style: TextStyle(
                  fontSize: 11,
                  color: TunlyTheme.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentSearch extends StatelessWidget {
  const _RecentSearch({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(vertical: 10),
    onPressed: onTap,
    child: Row(
      children: [
        const Icon(
          CupertinoIcons.clock,
          color: TunlyTheme.secondaryText,
          size: 18,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(color: Color(0xFFF5F5F6), fontSize: 15),
          ),
        ),
        const Icon(
          CupertinoIcons.arrow_up_left,
          color: TunlyTheme.secondaryText,
          size: 16,
        ),
      ],
    ),
  );
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid({required this.onTap});
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Genre('Pop', const Color(0xFFB65C78), width, onTap),
          _Genre('Hip-Hop', const Color(0xFF7454A6), width, onTap),
          _Genre('Chill', const Color(0xFF467B86), width, onTap),
          _Genre('Electronic', const Color(0xFFBC713C), width, onTap),
          _Genre('Indie', const Color(0xFF627A46), width, onTap),
          _Genre('R&B', const Color(0xFF4162A0), width, onTap),
          _Genre('Rock', const Color(0xFF99513F), width, onTap),
          _Genre('Jazz', const Color(0xFF516C92), width, onTap),
        ],
      );
    },
  );
}

class _Genre extends StatelessWidget {
  const _Genre(this.label, this.color, this.width, this.onTap);
  final String label;
  final Color color;
  final double width;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: () => onTap(label),
    child: Container(
      width: width,
      height: 102,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17),
      ),
      alignment: Alignment.topLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
