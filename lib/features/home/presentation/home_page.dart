import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverNavigationBar(
            largeTitle: Text(_greeting),
            backgroundColor: TunlyTheme.background.withValues(alpha: .9),
            border: null),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 112),
          sliver: SliverList.list(children: [
            const Text('Your soundtrack starts here.',
                style:
                    TextStyle(color: TunlyTheme.secondaryText, fontSize: 15)),
            const SizedBox(height: 23),
            feed.when(
              loading: () => const _FeedLoading(),
              error: (error, stack) =>
                  _LoadError(onRetry: () => ref.invalidate(homeFeedProvider)),
              data: (data) => data.trending.isEmpty &&
                      data.newReleases.isEmpty &&
                      data.madeForYou.isEmpty
                  ? _LoadError(onRetry: () => ref.invalidate(homeFeedProvider))
                  : _FeedContent(feed: data),
            ),
            const SizedBox(height: 24),
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
  const _FeedContent({required this.feed});
  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    final quickPicks = feed.trending.take(4).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTitle('Quick picks'),
      const SizedBox(height: 12),
      if (quickPicks.isNotEmpty)
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
      if (feed.trending.isNotEmpty) ...[
        const SizedBox(height: 28),
        const _SectionTitle('Trending now'),
        const SizedBox(height: 13),
        TrackCarousel(
          tracks: feed.trending,
          onTrackTap: (track) =>
              presentTrackPlayer(context, track, queue: feed.trending),
        ),
      ],
      if (feed.madeForYou.isNotEmpty) ...[
        const SizedBox(height: 20),
        const _SectionTitle('Made for you'),
        const SizedBox(height: 13),
        TrackCarousel(
          tracks: feed.madeForYou,
          onTrackTap: (track) =>
              presentTrackPlayer(context, track, queue: feed.madeForYou),
        ),
      ],
      if (feed.newReleases.isNotEmpty) ...[
        const SizedBox(height: 20),
        const _SectionTitle('New releases'),
        const SizedBox(height: 13),
        TrackCarousel(
          tracks: feed.newReleases,
          onTrackTap: (track) =>
              presentTrackPlayer(context, track, queue: feed.newReleases),
        ),
      ],
      const SizedBox(height: 10),
      const _SectionTitle('Find your mood'),
      const SizedBox(height: 12),
      const _MoodCards(),
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
            color: TunlyTheme.surface, borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [
          TrackArtwork(track: track, size: 64),
          const SizedBox(width: 10),
          Expanded(
              child: Text(track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)))
        ]),
      ));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -.3));
}

class _MoodCards extends StatelessWidget {
  const _MoodCards();
  @override
  Widget build(BuildContext context) =>
      const Wrap(spacing: 9, runSpacing: 9, children: [
        _MoodCard('Feel good', Color(0xFF477451)),
        _MoodCard('Late night', Color(0xFF454A87)),
        _MoodCard('Focus', Color(0xFF926436)),
        _MoodCard('New finds', Color(0xFF8D4568)),
      ]);
}

class _MoodCard extends StatelessWidget {
  const _MoodCard(this.title, this.color);
  final String title;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      width: 155,
      height: 76,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)));
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle('Just for you'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: List.generate(
              4,
              (_) => Container(
                  width: 160,
                  height: 64,
                  decoration: BoxDecoration(
                      color: TunlyTheme.surface,
                      borderRadius: BorderRadius.circular(12)))),
        ),
        const SizedBox(height: 24),
        const CupertinoActivityIndicator(radius: 12),
        const SizedBox(height: 24),
        Container(
            height: 142,
            decoration: BoxDecoration(
                color: TunlyTheme.surface,
                borderRadius: BorderRadius.circular(18))),
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
          const Text('We couldn’t reach the music catalog just now.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Check your connection and give it another try.',
              style: TextStyle(color: TunlyTheme.secondaryText, fontSize: 13)),
          const SizedBox(height: 9),
          CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onRetry,
              child: const Text('Try again')),
        ]),
      );
}
