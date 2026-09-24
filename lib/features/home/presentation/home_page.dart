import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../library/data/library_providers.dart';
import '../../music/data/music_providers.dart';
import '../../music/domain/track.dart';
import '../../music/presentation/track_widgets.dart';
import '../../player/presentation/now_playing_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider);
    final history = ref.watch(listeningHistoryProvider);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(_greeting),
          backgroundColor: TunlyTheme.background.withValues(alpha: .94),
          border: null,
          trailing: const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(CupertinoIcons.music_note, color: TunlyTheme.accent),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 174),
          sliver: SliverList.list(children: [
            const Text('Music that meets your moment.',
                style:
                    TextStyle(color: TunlyTheme.secondaryText, fontSize: 15)),
            const SizedBox(height: 20),
            feed.when(
              loading: () => const _FeedLoading(),
              error: (error, stack) =>
                  _LoadError(onRetry: () => ref.invalidate(homeFeedProvider)),
              data: (data) {
                if (data.trending.isEmpty &&
                    data.newReleases.isEmpty &&
                    data.madeForYou.isEmpty) {
                  return _LoadError(
                      onRetry: () => ref.invalidate(homeFeedProvider));
                }
                final recent = history.valueOrNull ?? const <Track>[];
                return _FeedContent(feed: data, recent: recent);
              },
            ),
            const SizedBox(height: 22),
            const Text(
                'Music listings and promotional artwork are provided courtesy of iTunes.',
                style: TextStyle(
                    fontSize: 11,
                    color: TunlyTheme.secondaryText,
                    height: 1.4)),
          ]),
        ),
      ],
    );
  }
}

class _FeedContent extends StatelessWidget {
  const _FeedContent({required this.feed, required this.recent});
  final HomeFeed feed;
  final List<Track> recent;

  @override
  Widget build(BuildContext context) {
    final quickPicks = feed.trending.take(6).toList();
    final fresh = feed.newReleases;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTitle('Quick picks'),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: quickPicks.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            mainAxisExtent: 64),
        itemBuilder: (context, index) => _QuickPick(
          track: quickPicks[index],
          onTap: () => presentTrackPlayer(context, quickPicks[index],
              queue: feed.trending),
        ),
      ),
      if (recent.isNotEmpty) ...[
        const SizedBox(height: 28),
        const _SectionTitle('Recently played'),
        const SizedBox(height: 13),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.take(6).length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              mainAxisExtent: 64),
          itemBuilder: (context, index) => _QuickPick(
            track: recent[index],
            onTap: () =>
                presentTrackPlayer(context, recent[index], queue: recent),
          ),
        ),
      ],
      if (feed.trending.isNotEmpty) ...[
        const SizedBox(height: 28),
        const _SectionTitle('Trending now'),
        const SizedBox(height: 13),
        TrackCarousel(
            tracks: feed.trending,
            onTrackTap: (track) =>
                presentTrackPlayer(context, track, queue: feed.trending)),
      ],
      if (fresh.isNotEmpty) ...[
        const SizedBox(height: 25),
        const _SectionTitle('Featured releases'),
        const SizedBox(height: 13),
        TrackCarousel(
            tracks: fresh,
            onTrackTap: (track) =>
                presentTrackPlayer(context, track, queue: fresh)),
      ],
      if (feed.madeForYou.isNotEmpty) ...[
        const SizedBox(height: 25),
        const _SectionTitle('Chill picks'),
        const SizedBox(height: 13),
        TrackCarousel(
            tracks: feed.madeForYou,
            onTrackTap: (track) =>
                presentTrackPlayer(context, track, queue: feed.madeForYou)),
      ],
      const SizedBox(height: 12),
      const _SectionTitle('Explore by genre'),
      const SizedBox(height: 13),
      _GenreGrid(
          onTap: (genre) =>
              context.go('/search?q=${Uri.encodeQueryComponent(genre)}')),
    ]);
  }
}

class _QuickPick extends StatelessWidget {
  const _QuickPick({required this.track, required this.onTap});
  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: TunlyTheme.surface,
              borderRadius: BorderRadius.circular(13)),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            TrackArtwork(track: track, size: 64),
            const SizedBox(width: 10),
            Expanded(
                child: Text(track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
          ]),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -.3));
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('Loading music for you'),
        const SizedBox(height: 14),
        Wrap(
            spacing: 9,
            runSpacing: 9,
            children: List.generate(
                6,
                (_) => Container(
                      width: 160,
                      height: 64,
                      decoration: BoxDecoration(
                          color: TunlyTheme.surface,
                          borderRadius: BorderRadius.circular(13)),
                    ))),
        const SizedBox(height: 24),
        const Center(child: CupertinoActivityIndicator(radius: 13)),
      ]);
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: TunlyTheme.surface, borderRadius: BorderRadius.circular(17)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('The music catalog is taking a moment.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Check your connection and try again.',
              style: TextStyle(color: TunlyTheme.secondaryText, fontSize: 13)),
          const SizedBox(height: 9),
          CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onRetry,
              child: const Text('Try again')),
        ]),
      );
}

class _GenreGrid extends StatelessWidget {
  const _GenreGrid({required this.onTap});
  final ValueChanged<String> onTap;

  static const _genres = <(String, Color)>[
    ('Pop', Color(0xFFEA2858)),
    ('Hip-Hop', Color(0xFF5B35D5)),
    ('R&B', Color(0xFF087B68)),
    ('Electronic', Color(0xFFE5A600)),
    ('Alternative', Color(0xFF2F62C7)),
    ('Rock', Color(0xFFD42A74)),
    ('Latin', Color(0xFF0B9B84)),
    ('Jazz', Color(0xFF314FD9)),
  ];

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _genres
                .map((item) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => onTap(item.$1),
                      child: Container(
                        width: width,
                        height: 92,
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: item.$2,
                            borderRadius: BorderRadius.circular(15)),
                        child: Stack(children: [
                          Positioned(
                              right: -26,
                              bottom: -47,
                              child: Transform.rotate(
                                  angle: -.28,
                                  child: Container(
                                      width: 100,
                                      height: 120,
                                      decoration: BoxDecoration(
                                          color: const Color(0x25000000),
                                          borderRadius:
                                              BorderRadius.circular(12))))),
                          Text(item.$1,
                              style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ))
                .toList());
      });
}
