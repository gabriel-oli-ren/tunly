import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../app/theme.dart';
import '../../music/domain/track.dart';
import '../data/lyrics_providers.dart';
import '../domain/lyrics.dart';

/// Inline lyrics panel. The calling player keeps the visible YouTube player
/// mounted above this panel while lyrics are open.
class LyricsPanel extends ConsumerStatefulWidget {
  const LyricsPanel({required this.track, required this.controller, super.key});
  final Track track;
  final YoutubePlayerController controller;
  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  final _scrollController = ScrollController();
  StreamSubscription<YoutubeVideoState>? _positionSubscription;
  Duration _position = Duration.zero;
  int _activeLine = -1;
  List<LyricLine> _lines = const [];

  @override
  void initState() {
    super.initState();
    _positionSubscription = widget.controller.videoStateStream.listen((state) {
      if (!mounted) return;
      _position = state.position;
      _syncLine();
    });
  }

  void _syncLine() {
    if (_lines.isEmpty) return;
    var next = 0;
    for (var index = 0; index < _lines.length; index++) {
      if (_lines[index].time <= _position) next = index;
    }
    if (next == _activeLine) return;
    _activeLine = next;
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = (next * 56.0)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      _scrollController.animateTo(target,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(lyricsProvider(widget.track));
    return Container(
      height: 320,
      decoration: BoxDecoration(
          color: TunlyTheme.surface, borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: value.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, stack) => const Center(
            child: Text('Lyrics aren’t available right now.',
                style: TextStyle(color: TunlyTheme.secondaryText))),
        data: (lyrics) {
          if (lyrics == null) {
            return const Center(
                child: Text('No lyrics found for this track.',
                    style: TextStyle(color: TunlyTheme.secondaryText)));
          }
          _lines = lyrics.lines;
          if (_activeLine < 0 && _lines.isNotEmpty) _activeLine = 0;
          if (!lyrics.synced) {
            return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Text(lyrics.plainText,
                    style: const TextStyle(
                        fontSize: 16, height: 1.7, color: Color(0xFFD2D3D7))));
          }
          return ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: lyrics.lines.length,
            itemBuilder: (context, index) => CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              onPressed: () => widget.controller.seekTo(
                  seconds: lyrics.lines[index].time.inMilliseconds / 1000,
                  allowSeekAhead: true),
              child: Text(lyrics.lines[index].text,
                  style: TextStyle(
                      fontSize: index == _activeLine ? 20 : 17,
                      fontWeight: index == _activeLine
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: index == _activeLine
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF8B8F98))),
            ),
          );
        },
      ),
    );
  }
}
