import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../providers/music_provider.dart';
import '../widgets/liquid_glass_components.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late YoutubePlayerController _youtubeController;
  bool _isControllerInitialized = false;

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }

  void _initializeYouTubeController(String videoId) {
    if (_isControllerInitialized) {
      _youtubeController.load(videoId);
      return;
    }

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        controlsVisibleAtStart: false,
        loop: false,
      ),
    );

    _isControllerInitialized = true;
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins}:${secs.toString().padStart(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        final song = musicProvider.currentSong;
        if (song == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No song selected',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Initialize YouTube controller when song changes
        if (!_isControllerInitialized || 
            _youtubeController.metadata.videoId != song.youtubeId) {
          _initializeYouTubeController(song.youtubeId);
          
          // Sync YouTube player with music provider state
          if (musicProvider.isPlaying) {
            _youtubeController.play();
          } else {
            _youtubeController.pause();
          }
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Background with blur effect
              Positioned.fill(
                child: Image.network(
                  song.coverImage,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.8),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              // Liquid Glass Layer for UI elements
              LiquidGlassLayer(
                settings: const LiquidGlassSettings(
                  thickness: 10,
                  blur: 5,
                  glassColor: Color(0x0AFFFFFF),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 40),
                        _buildAlbumArt(song),
                        const SizedBox(height: 40),
                        _buildSongInfo(song),
                        const SizedBox(height: 40),
                        _buildProgressBar(musicProvider),
                        const SizedBox(height: 40),
                        _buildControls(musicProvider),
                        const SizedBox(height: 40),
                        _buildAdditionalControls(),
                      ],
                    ),
                  ),
                ),
              ),
              // Hidden YouTube player
              Positioned(
                top: -1000,
                left: -1000,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: YoutubePlayer(
                    controller: _youtubeController,
                    showVideoProgressIndicator: false,
                    onEnded: (meta) {
                      musicProvider.playNext();
                    },
                    onPlayerStateChanged: (state) {
                      if (state == PlayerState.playing) {
                        musicProvider.togglePlayPause();
                      } else if (state == PlayerState.paused) {
                        musicProvider.togglePlayPause();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LiquidGlassButton(
            onPressed: () => Navigator.pop(context),
            borderRadius: 22,
            width: 44,
            height: 44,
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          LiquidGlassButton(
            onPressed: () {},
            borderRadius: 22,
            width: 44,
            height: 44,
            child: const Icon(
              Icons.more_horiz,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(dynamic song) {
    return Center(
      child: LiquidGlassCard(
        borderRadius: 24,
        blur: 20,
        thickness: 20,
        width: 280,
        height: 280,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            song.coverImage,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(dynamic song) {
    return Column(
      children: [
        Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          song.artist,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(MusicProvider musicProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          LiquidGlassSlider(
            value: musicProvider.progress,
            onChanged: (value) {
              musicProvider.setProgress(value);
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(musicProvider.progress * 200), // Assuming 200 seconds duration
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  musicProvider.currentSong?.duration ?? '0:00',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(MusicProvider musicProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LiquidGlassButton(
          onPressed: musicProvider.playPrevious,
          borderRadius: 32,
          width: 64,
          height: 64,
          child: const Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 24),
        LiquidGlassButton(
          onPressed: () {
            musicProvider.togglePlayPause();
            if (musicProvider.isPlaying) {
              _youtubeController.play();
            } else {
              _youtubeController.pause();
            }
          },
          borderRadius: 44,
          width: 88,
          height: 88,
          child: Icon(
            musicProvider.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(width: 24),
        LiquidGlassButton(
          onPressed: musicProvider.playNext,
          borderRadius: 32,
          width: 64,
          height: 64,
          child: const Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        LiquidGlassButton(
          onPressed: () {},
          borderRadius: 28,
          width: 56,
          height: 56,
          child: const Icon(
            Icons.shuffle,
            color: Colors.white,
            size: 24,
          ),
        ),
        LiquidGlassButton(
          onPressed: () {},
          borderRadius: 28,
          width: 56,
          height: 56,
          child: const Icon(
            Icons.repeat,
            color: Colors.white,
            size: 24,
          ),
        ),
        LiquidGlassButton(
          onPressed: () {},
          borderRadius: 28,
          width: 56,
          height: 56,
          child: const Icon(
            Icons.favorite_border,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}
