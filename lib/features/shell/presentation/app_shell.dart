import 'dart:ui';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../home/presentation/home_page.dart';
import '../../home/presentation/feed_page.dart';
import '../../library/data/library_providers.dart';
import '../../library/presentation/library_page.dart';
import '../../music/domain/track.dart';
import '../../music/presentation/track_widgets.dart';
import '../../player/presentation/now_playing_sheet.dart';
import '../../search/presentation/search_page.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.tab, this.searchQuery, super.key});
  final String tab;
  final String? searchQuery;

  int get _index => switch (tab) {
    'search' => 1,
    'library' => 2,
    'feed' => 3,
    _ => 0,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = [
      const HomePage(),
      SearchPage(initialQuery: searchQuery),
      const LibraryPage(),
      const FeedPage(),
    ];
    final history =
        ref.watch(listeningHistoryProvider).valueOrNull ?? const <Track>[];
    final lastTrack = history.isEmpty ? null : history.first;
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(index: _index, children: pages),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lastTrack != null) ...[
                    _MiniPlayer(track: lastTrack),
                    const SizedBox(height: 8),
                  ],
                  CNTabBar(
                    items: const [
                      CNTabBarItem(label: 'Home', icon: CNSymbol('house.fill')),
                      CNTabBarItem(label: 'Search', icon: CNSymbol('magnifyingglass')),
                      CNTabBarItem(label: 'Your Library', icon: CNSymbol('music.note.list')),
                      CNTabBarItem(label: 'Feed', icon: CNSymbol('bubble.left.fill')),
                    ],
                    currentIndex: _index,
                    onTap: (index) {
                      HapticFeedback.selectionClick();
                      context.go(switch (index) {
                        1 => '/search',
                        2 => '/library',
                        3 => '/feed',
                        _ => '/home',
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xB81A2745),
          border: Border.all(color: const Color(0x24FFFFFF)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const SizedBox(width: 9),
            TrackArtwork(track: track, size: 50),
            const SizedBox(width: 11),
            Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => presentTrackPlayer(context, track),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TunlyTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: CNButton.icon(
                icon: const CNSymbol('play.fill'),
                onPressed: () => presentTrackPlayer(context, track),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
