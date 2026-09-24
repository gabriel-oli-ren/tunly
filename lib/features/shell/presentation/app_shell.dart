import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cupertino_native/cupertino_native.dart';

import '../../../app/theme.dart';
import '../../../core/presentation/native_cupertino_controls.dart';
import '../../home/presentation/home_page.dart';
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
    _ => 0,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = [
      const HomePage(),
      SearchPage(initialQuery: searchQuery),
      const LibraryPage(),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: usesNativeCupertino
                          ? CNTabBar(
                              items: const [
                                CNTabBarItem(
                                  label: 'Home',
                                  icon: CNSymbol('house.fill'),
                                ),
                                CNTabBarItem(
                                  label: 'Search',
                                  icon: CNSymbol('magnifyingglass'),
                                ),
                                CNTabBarItem(
                                  label: 'Library',
                                  icon: CNSymbol('music.note.list'),
                                ),
                              ],
                              currentIndex: _index,
                              onTap: (index) => context.go(switch (index) {
                                1 => '/search',
                                2 => '/library',
                                _ => '/home',
                              }),
                              tint: const Color(0xFFF7F8FC),
                              backgroundColor: const Color(0x00000000),
                              height: 57,
                              shrinkCentered: false,
                            )
                          : Container(
                              height: 67,
                              decoration: BoxDecoration(
                                color: const Color(0xD916203A),
                                border: Border.all(
                                  color: const Color(0x20FFFFFF),
                                ),
                                borderRadius: BorderRadius.circular(27),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 5,
                              ),
                              child: Row(
                                children:
                                    [
                                          const _NavItem(
                                            index: 0,
                                            label: 'Home',
                                            icon: CupertinoIcons.house_fill,
                                          ),
                                          const _NavItem(
                                            index: 1,
                                            label: 'Search',
                                            icon: CupertinoIcons.search,
                                          ),
                                          const _NavItem(
                                            index: 2,
                                            label: 'Library',
                                            icon:
                                                CupertinoIcons.music_note_list,
                                          ),
                                        ]
                                        .map(
                                          (item) => Expanded(
                                            child: CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () => context.go(
                                                switch (item.index) {
                                                  1 => '/search',
                                                  2 => '/library',
                                                  _ => '/home',
                                                },
                                              ),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                curve: Curves.easeOut,
                                                decoration: BoxDecoration(
                                                  color: item.index == _index
                                                      ? const Color(0xFF29365A)
                                                      : const Color(0x00000000),
                                                  borderRadius:
                                                      BorderRadius.circular(23),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      item.icon,
                                                      size: 20,
                                                      color:
                                                          item.index == _index
                                                          ? const Color(
                                                              0xFFF7F8FC,
                                                            )
                                                          : TunlyTheme
                                                                .secondaryText,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      item.label,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            item.index == _index
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                        color:
                                                            item.index == _index
                                                            ? const Color(
                                                                0xFFF7F8FC,
                                                              )
                                                            : TunlyTheme
                                                                  .secondaryText,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                    ),
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

class _NavItem {
  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
  });
  final int index;
  final String label;
  final IconData icon;
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
          color: const Color(0xE51A2745),
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
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => presentTrackPlayer(context, track),
              child: const Icon(CupertinoIcons.play_fill, size: 22),
            ),
          ],
        ),
      ),
    ),
  );
}
