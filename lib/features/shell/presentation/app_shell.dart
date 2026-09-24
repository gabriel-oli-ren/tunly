import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../home/presentation/home_page.dart';
import '../../library/presentation/library_page.dart';
import '../../search/presentation/search_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.tab, super.key});
  final String tab;

  int get _index => switch (tab) { 'search' => 1, 'library' => 2, _ => 0 };

  @override
  Widget build(BuildContext context) {
    final pages = const [HomePage(), SearchPage(), LibraryPage()];
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          SafeArea(
              bottom: false,
              child: IndexedStack(index: _index, children: pages)),
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: CupertinoTabBar(
                    currentIndex: _index,
                    backgroundColor: const Color(0xCC191A1E),
                    activeColor: TunlyTheme.accent,
                    inactiveColor: TunlyTheme.secondaryText,
                    border:
                        const Border(top: BorderSide(color: Color(0x22FFFFFF))),
                    onTap: (index) => context.go(switch (index) {
                      1 => '/search',
                      2 => '/library',
                      _ => '/home'
                    }),
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
                      BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.search), label: 'Search'),
                      BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.music_note_list),
                          label: 'Library'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
