import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
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
                  _LiquidGlassTabBar(
                    currentIndex: _index,
                    onSelect: (index) {
                      HapticFeedback.selectionClick();
                      context.go(switch (index) {
                        1 => '/search',
                        2 => '/library',
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

class _LiquidGlassTabBar extends StatelessWidget {
  const _LiquidGlassTabBar({
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const _items = <(String, IconData)>[
    ('Home', CupertinoIcons.house_fill),
    ('Search', CupertinoIcons.search),
    ('Your Library', CupertinoIcons.music_note_list),
  ];

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(34),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF21D2028), Color(0xF20C0D12)],
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: const Color(0x36FFFFFF), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 26,
              offset: Offset(0, 9),
            ),
            BoxShadow(
              color: Color(0x1AFFFFFF),
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = (constraints.maxWidth - 12) / 3;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  left: 6 + segmentWidth * currentIndex,
                  top: 6,
                  bottom: 6,
                  width: segmentWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF5080A10),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x12FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final selected = currentIndex == index;
                    final color = selected
                        ? const Color(0xFF3982FF)
                        : const Color(0xFFE9EAF0);
                    return Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: () => onSelect(index),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.08 : 1,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: Icon(item.$2, size: 26, color: color),
                              ),
                              const SizedBox(height: 3),
                              Text(item.$1),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0x66FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
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
