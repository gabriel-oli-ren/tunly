import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
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

/// Large, artwork-backed lyrics view used inside the Now Playing sheet.
/// The YouTube player remains visible above this view so the embedded video
/// is never hidden while it is playing.
class LyricsFullscreenView extends ConsumerStatefulWidget {
  const LyricsFullscreenView({
    required this.track,
    required this.controller,
    super.key,
  });

  final Track track;
  final YoutubePlayerController controller;

  @override
  ConsumerState<LyricsFullscreenView> createState() =>
      _LyricsFullscreenViewState();
}

class _LyricsFullscreenViewState extends ConsumerState<LyricsFullscreenView> {
  final _scrollController = ScrollController();
  Timer? _positionTimer;
  Duration _position = Duration.zero;
  int _activeLine = -1;
  List<LyricLine> _lines = const [];

  @override
  void initState() {
    super.initState();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        final value = widget.controller.value;
        _position = Duration(seconds: (value.metaData.duration.inSeconds * value.playbackRate).round());
        _syncActiveLine();
      }
    });
  }

  void _syncActiveLine() {
    if (_lines.isEmpty) return;
    var next = 0;
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].time <= _position) next = i;
    }
    if (next == _activeLine) return;
    _activeLine = next;
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = (next * 70.0)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncLyrics = ref.watch(lyricsProvider(widget.track));
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 34, sigmaY: 34),
          child: Image.network(
            widget.track.artworkUrl.toString(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: TunlyTheme.background),
          ),
        ),
        const ColoredBox(color: Color(0xE8090B12)),
        asyncLyrics.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, _) => const Center(
            child: Text(
              'Lyrics aren’t available right now.',
              style: TextStyle(color: TunlyTheme.secondaryText),
            ),
          ),
          data: (lyrics) {
            if (lyrics == null) {
              return const Center(
                child: Text(
                  'No lyrics found for this song.',
                  style: TextStyle(color: TunlyTheme.secondaryText),
                ),
              );
            }
            if (!lyrics.synced || lyrics.lines.isEmpty) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 50),
                child: Text(
                  lyrics.plainText,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              );
            }
            _lines = lyrics.lines;
            if (_activeLine < 0) _activeLine = 0;
            return ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 38, 28, 80),
              itemCount: lyrics.lines.length,
              itemBuilder: (context, index) {
                final active = index == _activeLine;
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.centerLeft,
                  onPressed: () => widget.controller.seekTo(
                    seconds: lyrics.lines[index].time.inMilliseconds / 1000,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      fontSize: active ? 29 : 25,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? Colors.white
                          : const Color(0xFF858895).withValues(alpha: .63),
                    ),
                    child: Text(lyrics.lines[index].text),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  final _scrollController = ScrollController();
  Timer? _positionTimer;
  Duration _position = Duration.zero;
  int _activeLine = -1;
  List<LyricLine> _lines = const [];

  @override
  void initState() {
    super.initState();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        final value = widget.controller.value;
        _position = Duration(seconds: (value.metaData.duration.inSeconds * value.playbackRate).round());
        _syncLine();
      }
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
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(lyricsProvider(widget.track));
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: TunlyTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: value.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, stack) => const Center(
          child: Text(
            'Lyrics aren’t available right now.',
            style: TextStyle(color: TunlyTheme.secondaryText),
          ),
        ),
        data: (lyrics) {
          if (lyrics == null) {
            return const Center(
              child: Text(
                'No lyrics found for this track.',
                style: TextStyle(color: TunlyTheme.secondaryText),
              ),
            );
          }
          _lines = lyrics.lines;
          if (_activeLine < 0 && _lines.isNotEmpty) _activeLine = 0;
          if (!lyrics.synced) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Text(
                lyrics.plainText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: Color(0xFFD2D3D7),
                ),
              ),
            );
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
              ),
              child: Text(
                lyrics.lines[index].text,
                style: TextStyle(
                  fontSize: index == _activeLine ? 20 : 17,
                  fontWeight: index == _activeLine
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: index == _activeLine
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF8B8F98),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
