import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../music/data/music_providers.dart';
import '../../music/presentation/track_widgets.dart';
import '../../player/presentation/now_playing_sheet.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Feed'),
          border: null,
          transitionBetweenRoutes: false,
        ),
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(homeFeedProvider);
            await ref.read(homeFeedProvider.future);
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 200),
          sliver: SliverList.list(
            children: [
              const Text(
                'Fresh music and what’s moving around you.',
                style: TextStyle(color: TunlyTheme.secondaryText, fontSize: 15),
              ),
              const SizedBox(height: 24),
              feed.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child: CupertinoActivityIndicator(radius: 14),
                  ),
                ),
                error: (error, stack) =>
                    _FeedError(onRetry: () => ref.invalidate(homeFeedProvider)),
                data: (data) {
                  if (data.trending.isEmpty && data.newReleases.isEmpty) {
                    return _FeedError(
                      onRetry: () => ref.invalidate(homeFeedProvider),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Popular in ${data.regionName}',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TrackCarousel(
                        tracks: data.trending,
                        onTrackTap: (track) => presentTrackPlayer(
                          context,
                          track,
                          queue: data.trending,
                        ),
                      ),
                      if (data.newReleases.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        const Text(
                          'New releases',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TrackCarousel(
                          tracks: data.newReleases,
                          onTrackTap: (track) => presentTrackPlayer(
                            context,
                            track,
                            queue: data.newReleases,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
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

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Music is taking a moment to load.',
        style: TextStyle(color: TunlyTheme.secondaryText),
      ),
      CupertinoButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}
