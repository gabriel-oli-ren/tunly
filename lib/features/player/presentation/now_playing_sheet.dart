import 'dart:async';
import 'dart:math';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Curves, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../app/theme.dart';
import '../../../core/presentation/native_cupertino_controls.dart';
import '../../library/data/library_providers.dart';
import '../../library/data/local_library.dart';
import '../../music/data/music_providers.dart';
import '../../music/domain/track.dart';
import '../../music/presentation/track_widgets.dart';
import '../../music/presentation/track_palette_provider.dart';
import '../../lyrics/presentation/lyrics_view.dart';
import '../data/video_match.dart';

Future<void> presentTrackPlayer(
  BuildContext context,
  Track track, {
  List<Track> queue = const [],
}) async {
  await showCupertinoModalPopup<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (_) =>
        _NowPlayingSheet(track: track, queue: queue.isEmpty ? [track] : queue),
  );
}

class _NowPlayingSheet extends ConsumerStatefulWidget {
  const _NowPlayingSheet({required this.track, required this.queue});
  final Track track;
  final List<Track> queue;

  @override
  ConsumerState<_NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends ConsumerState<_NowPlayingSheet> {
  YoutubePlayerController? _controller;
  late int _queueIndex;
  bool _loading = true;
  bool _tryingAnotherSource = false;
  bool _showLyrics = false;
  String? _message;
  List<VideoMatch> _matches = const [];
  int _matchIndex = 0;
  int? _prefetchedQueueIndex;
  List<VideoMatch> _prefetchedMatches = const [];
  Timer? _sleepTimer;
  bool _shuffle = false;
  bool _repeatCurrent = false;
  final Set<String> _failedVideoIds = <String>{};
  String? _sleepLabel;
  PlayerState _playerState = PlayerState.unknown;
  Track get _track => widget.queue[_queueIndex];

  @override
  void initState() {
    super.initState();
    final selectedIndex = widget.queue.indexWhere(
      (item) => item.id == widget.track.id,
    );
    _queueIndex = selectedIndex < 0 ? 0 : selectedIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_recordTrack(widget.track));
      _resolveTrack();
    });
  }

  Future<void> _recordTrack(Track track) async {
    await ref.read(localLibraryProvider).recordListen(track);
    ref.invalidate(listeningHistoryProvider);
  }

  Future<void> _resolveTrack() async {
    if (!mounted) return;
    _failedVideoIds.clear();
    setState(() {
      _loading = true;
      _tryingAnotherSource = false;
      _message = null;
    });
    try {
      final matches = await ref
          .read(youtubeVideoResolverProvider)
          .resolve(
            _track,
            onFallback: () {
              if (mounted) setState(() => _tryingAnotherSource = true);
            },
          );
      if (!mounted) return;
      if (matches.isEmpty) {
        setState(() {
          _loading = false;
          _message = 'We couldn\'t find a close YouTube match. Try another song.';
        });
        return;
      }
      await _controller?.close();
      _matches = matches;
      _matchIndex = 0;
      _controller = YoutubePlayerController.fromVideoId(
        videoId: matches.first.videoId,
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: false,
          strictRelatedVideos: true,
          playsInline: true,
          privacyEnhancedMode: false,
          loop: false,
        ),
      );
      _watchController();
      setState(() {
        _loading = false;
        _tryingAnotherSource = false;
      });
      _prefetchNext();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _tryingAnotherSource = false;
        _message = 'Couldn\'t find a playable YouTube video. Check your connection and try again.';
      });
    }
  }

  void _watchController() {
    final controller = _controller;
    if (controller == null) return;
    controller.stream.listen((value) {
      if (value.playerState != _playerState && mounted) {
        setState(() => _playerState = value.playerState);
      }
      if (value.playerState == PlayerState.playing) {
        if (_message != null && mounted) setState(() => _message = null);
      }
      if (value.playerState == PlayerState.ended && mounted) {
        if (_repeatCurrent) {
          _loadMatch(_matchIndex);
        } else {
          _playNext();
        }
      }
    });
  }

  Future<void> _playNext() async {
    final nextIndex = _shuffle && _prefetchedQueueIndex != null
        ? _prefetchedQueueIndex!
        : _nextQueueIndex();
    if (nextIndex >= widget.queue.length) {
      if (_matchIndex + 1 < _matches.length) {
        await _loadMatch(_matchIndex + 1);
      }
      return;
    }
    var matches = _prefetchedQueueIndex == nextIndex
        ? _prefetchedMatches
        : <VideoMatch>[];
    if (matches.isEmpty) {
      setState(() {
        _queueIndex = nextIndex;
        _loading = true;
      });
      try {
        matches = await ref.read(youtubeVideoResolverProvider).resolve(_track);
      } catch (_) {
        matches = const [];
      }
    }
    if (!mounted) return;
    if (matches.isEmpty) {
      setState(() {
        _loading = false;
        _message = 'We couldn\'t find the next song. Try another source.';
      });
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _queueIndex = nextIndex;
      _matches = matches;
      _matchIndex = 0;
      _failedVideoIds.clear();
      _message = null;
      _showLyrics = false;
      _prefetchedQueueIndex = null;
      _prefetchedMatches = const [];
    });
    await ref.read(localLibraryProvider).recordListen(_track);
    ref.invalidate(listeningHistoryProvider);
    try {
      await controller.loadVideoById(videoId: matches.first.videoId);
      _prefetchNext();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Tap play in the YouTube player to continue.',
        );
      }
    }
  }

  int _nextQueueIndex() {
    if (!_shuffle || widget.queue.length < 2) return _queueIndex + 1;
    final options = List<int>.generate(widget.queue.length, (index) => index)
      ..remove(_queueIndex);
    options.shuffle(Random());
    return options.first;
  }

  Future<void> _playPrevious() async {
    if (_queueIndex <= 0) return;
    final previousIndex = _queueIndex - 1;
    setState(() {
      _queueIndex = previousIndex;
      _loading = true;
      _showLyrics = false;
      _prefetchedQueueIndex = null;
      _prefetchedMatches = const [];
    });
    List<VideoMatch> matches;
    try {
      matches = await ref.read(youtubeVideoResolverProvider).resolve(_track);
    } catch (_) {
      matches = const [];
    }
    if (!mounted) return;
    if (matches.isEmpty || _controller == null) {
      setState(() {
        _loading = false;
        _message = 'We couldn\'t find a match for the previous song.';
      });
      return;
    }
    setState(() {
      _matches = matches;
      _matchIndex = 0;
      _failedVideoIds.clear();
      _loading = false;
      _message = null;
    });
    await ref.read(localLibraryProvider).recordListen(_track);
    ref.invalidate(listeningHistoryProvider);
    await _controller!.loadVideoById(videoId: matches.first.videoId);
    _prefetchNext();
  }

  Future<void> _prefetchNext() async {
    final nextIndex = _shuffle ? _nextQueueIndex() : _queueIndex + 1;
    final currentIndex = _queueIndex;
    if (nextIndex >= widget.queue.length ||
        _prefetchedQueueIndex == nextIndex) {
      return;
    }
    try {
      final matches = await ref
          .read(youtubeVideoResolverProvider)
          .resolve(widget.queue[nextIndex]);
      if (!mounted || _queueIndex != currentIndex || matches.isEmpty) return;
      _prefetchedQueueIndex = nextIndex;
      _prefetchedMatches = matches;
    } catch (_) {
      // Next item is resolved on demand if prefetch is unavailable.
    }
  }

  Future<void> _setSleepTimer() async {
    final minutes = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Sleep timer'),
        actions: [
          for (final value in [15, 30, 45, 60])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, value),
              child: Text('$value minutes'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('Turn off timer'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (minutes == null) return;
    _sleepTimer?.cancel();
    if (minutes == 0) {
      setState(() => _sleepLabel = null);
      return;
    }
    setState(() => _sleepLabel = '$minutes min');
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      if (_controller != null) {
        _controller!.stopVideo();
      }
      if (mounted) setState(() => _sleepLabel = 'Paused');
    });
  }

  Future<void> _toggleLike() async {
    await ref.read(localLibraryProvider).toggleLiked(_track);
    ref.invalidate(likedTracksProvider);
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    if (_playerState == PlayerState.playing) {
      controller.stopVideo();
      return;
    }
    setState(() {
      _tryingAnotherSource = false;
      _message = null;
    });
    // Called directly from a user's tap: iOS requires a fresh gesture before
    // a web view is allowed to start audio.
    controller.playVideo();
  }

  Future<void> _closePlayer() async {
    final controller = _controller;
    if (controller != null) {
      await controller.close();
      _controller = null;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addToPlaylist(List<LocalPlaylist> playlists) async {
    if (playlists.isEmpty) return;
    final selected = await showCupertinoModalPopup<LocalPlaylist>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add to playlist'),
        actions: playlists
            .map(
              (playlist) => CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, playlist),
                child: Text(playlist.name),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await ref.read(localLibraryProvider).addToPlaylist(selected, _track);
    ref.invalidate(localPlaylistsProvider);
  }

  Future<void> _loadMatch(int index) async {
    final controller = _controller;
    if (controller == null || index >= _matches.length) return;
    setState(() {
      _matchIndex = index;
      _tryingAnotherSource = true;
      _message = null;
    });
    try {
      await controller.loadVideoById(videoId: _matches[index].videoId);
      if (mounted) setState(() => _tryingAnotherSource = false);
    } catch (_) {
      if (index + 1 < _matches.length) {
        await _loadMatch(index + 1);
      } else if (mounted) {
        setState(() {
          _tryingAnotherSource = false;
          _message = 'This video can\'t play here. Try another song.';
        });
      }
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    final controller = _controller;
    if (controller != null) {
      controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final controller = _controller;
    final liked =
        ref
            .watch(likedTracksProvider)
            .valueOrNull
            ?.any((item) => item.id == _track.id) ??
        false;
    final playlists =
        ref.watch(localPlaylistsProvider).valueOrNull ??
        const <LocalPlaylist>[];
    final artworkColor =
        ref.watch(trackPaletteProvider(_track)).valueOrNull ??
        TunlyTheme.elevated;
    return Material(
      color: const Color(0xFF111216),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              artworkColor.withValues(alpha: .28),
              const Color(0xFF111216),
            ],
            stops: const [0, .62],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: media.height * .94,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x55FFFFFF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'NOW PLAYING',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.8,
                            color: TunlyTheme.secondaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TunlyNativeIconButton(
                        symbol: 'xmark',
                        onPressed: _closePlayer,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: controller != null
                      ? SizedBox(
                          height: 1,
                          child: Opacity(
                            opacity: 0,
                            child: YoutubePlayer(
                              controller: controller,
                              aspectRatio: 1.45,
                            ),
                          ),
                        )
                      : AspectRatio(
                          aspectRatio: 1.45,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  _track.artworkUrl.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(
                                        color: TunlyTheme.surface,
                                      ),
                                ),
                                const ColoredBox(color: Color(0x66000000)),
                                Center(
                                  child: _loading || _tryingAnotherSource
                                      ? const CupertinoActivityIndicator(
                                          radius: 15,
                                        )
                                      : const Icon(
                                          CupertinoIcons.play_rectangle,
                                          size: 54,
                                          color: Color(0xDDFFFFFF),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                if (_loading || _tryingAnotherSource)
                  const Text(
                    'Finding a playable video…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TunlyTheme.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                Expanded(
                  child: _showLyrics && controller != null
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
                              child: Row(
                                children: [
                                  TrackArtwork(track: _track, size: 48),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _track.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          _track.artist,
                                          style: const TextStyle(
                                            color: TunlyTheme.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.all(8),
                                    onPressed: () =>
                                        setState(() => _showLyrics = false),
                                    child: const Icon(
                                      CupertinoIcons.chevron_down,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: LyricsFullscreenView(
                                track: _track,
                                controller: controller,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                          children: [
                            if (_message != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: TunlyTheme.secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                              CupertinoButton(
                                onPressed: _resolveTrack,
                                child: const Text('Try again'),
                              ),
                            ],
                            Center(
                              child: GestureDetector(
                                onTap: () => setState(() => _showLyrics = true),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    AnimatedScale(
                                      scale: _playerState == PlayerState.playing
                                          ? 1
                                          : .985,
                                      duration: const Duration(
                                        milliseconds: 420,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: Hero(
                                        tag: 'tunly-art-${_track.id}',
                                        child: TrackArtwork(
                                          track: _track,
                                          size:
                                              (MediaQuery.sizeOf(
                                                        context,
                                                      ).width -
                                                      48)
                                                  .clamp(210, 340)
                                                  .toDouble(),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: const Color(0x99090B12),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: const Color(0x44FFFFFF),
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10),
                                          child: Icon(
                                            CupertinoIcons.quote_bubble_fill,
                                            size: 19,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _track.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: TunlyTheme.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TunlyNativeIconButton(
                                  symbol: liked ? 'heart.fill' : 'heart',
                                  tint: liked
                                      ? TunlyTheme.accent
                                      : TunlyTheme.secondaryText,
                                  onPressed: _toggleLike,
                                ),
                                TunlyNativeIconButton(
                                  symbol: 'text.badge.plus',
                                  tint: TunlyTheme.secondaryText,
                                  onPressed: playlists.isEmpty
                                      ? null
                                      : () => _addToPlaylist(playlists),
                                ),
                              ],
                            ),
                            if (controller != null) ...[
                              const SizedBox(height: 14),
                              if (_playerState != PlayerState.playing &&
                                  _message == null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: CupertinoButton.filled(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 26,
                                      vertical: 12,
                                    ),
                                    onPressed: _togglePlayback,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.play_fill,
                                          size: 16,
                                        ),
                                        SizedBox(width: 9),
                                        Text('Start listening'),
                                      ],
                                    ),
                                  ),
                                ),
                              _VideoProgress(
                                key: ValueKey(_track.id),
                                controller: controller,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TunlyNativeIconButton(
                                    size: 42,
                                    symbol: 'shuffle',
                                    tint: _shuffle
                                        ? TunlyTheme.accent
                                        : TunlyTheme.secondaryText,
                                    onPressed: () =>
                                        setState(() => _shuffle = !_shuffle),
                                  ),
                                  TunlyNativeIconButton(
                                    size: 48,
                                    symbol: 'backward.end.fill',
                                    tint: TunlyTheme.secondaryText,
                                    onPressed: _playPrevious,
                                  ),
                                  TunlyNativeIconButton(
                                    size: 58,
                                    symbol: _playerState == PlayerState.playing
                                        ? 'pause.fill'
                                        : 'play.fill',
                                    tint: TunlyTheme.accent,
                                    onPressed: _togglePlayback,
                                  ),
                                  TunlyNativeIconButton(
                                    size: 48,
                                    symbol: 'forward.end.fill',
                                    tint: TunlyTheme.secondaryText,
                                    onPressed: _playNext,
                                  ),
                                  TunlyNativeIconButton(
                                    size: 42,
                                    symbol: 'repeat.1',
                                    tint: _repeatCurrent
                                        ? TunlyTheme.accent
                                        : TunlyTheme.secondaryText,
                                    onPressed: () => setState(
                                      () => _repeatCurrent = !_repeatCurrent,
                                    ),
                                  ),
                                ],
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                onPressed: _setSleepTimer,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(CupertinoIcons.timer, size: 17),
                                    const SizedBox(width: 7),
                                    Text(
                                      _sleepLabel == null
                                          ? 'Sleep timer'
                                          : 'Sleep timer · $_sleepLabel',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                onPressed: () =>
                                    setState(() => _showLyrics = true),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.quote_bubble, size: 18),
                                    SizedBox(width: 8),
                                    Text('Show lyrics'),
                                  ],
                                ),
                              ),
                            ],
                            if (widget.queue.length > 1) ...[
                              const SizedBox(height: 14),
                              const Text(
                                'Up next',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...widget.queue
                                  .skip(_queueIndex + 1)
                                  .take(6)
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: Row(
                                        children: [
                                          TrackArtwork(track: item, size: 42),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            item.artist,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: TunlyTheme.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ],
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: TunlyTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Playback is provided by YouTube. Use the visible player controls to start, pause, or change playback. Closing this view stops playback.',
                                style: TextStyle(
                                  color: TunlyTheme.secondaryText,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  onPressed: () => launchUrl(
                                    Uri.parse(
                                      'https://www.youtube.com/t/terms',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: const Text(
                                    'YouTube Terms',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                const Text(
                                  '·',
                                  style: TextStyle(
                                    color: TunlyTheme.secondaryText,
                                  ),
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  onPressed: () => launchUrl(
                                    Uri.parse(
                                      'https://policies.google.com/privacy',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: const Text(
                                    'Privacy',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoProgress extends StatefulWidget {
  const _VideoProgress({required this.controller, super.key});
  final YoutubePlayerController controller;

  @override
  State<_VideoProgress> createState() => _VideoProgressState();
}

class _VideoProgressState extends State<_VideoProgress> {
  Timer? _updateTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        final value = widget.controller.value;
        setState(() {
          _position = Duration(seconds: (value.metaData.duration.inSeconds * value.playbackRate).round());
          _duration = value.metaData.duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = _duration.inMilliseconds.toDouble();
    final remaining = _duration - _position;
    final valuePosition = _position.inMilliseconds
        .toDouble()
        .clamp(0, max > 0 ? max : 1)
        .toDouble();
    return Column(
      children: [
        CNSlider(
          value: valuePosition,
          min: 0,
          max: max > 0 ? max : 1,
          onChanged: max <= 0
              ? (next) {}
              : (next) => widget.controller.seekTo(
                  seconds: next / 1000,
                ),
        ),
        Row(
          children: [
            Text(
              _format(_position),
              style: const TextStyle(
                fontSize: 11,
                color: TunlyTheme.secondaryText,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: TunlyTheme.secondaryText,
                  ),
                ),
              ),
            ),
            Text(
              '-${_format(remaining.isNegative ? Duration.zero : remaining)}',
              style: const TextStyle(
                fontSize: 11,
                color: TunlyTheme.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _format(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${duration.inMinutes}:${two(duration.inSeconds.remainder(60))}';
  }
}
