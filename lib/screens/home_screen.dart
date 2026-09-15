import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/songs_data.dart';
import '../providers/music_provider.dart';
import '../widgets/liquid_glass_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeaturedAlbums(context),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Most Played'),
                    const SizedBox(height: 16),
                    _buildMostPlayed(context),
                    const SizedBox(height: 32),
                    _buildSectionTitle('New Releases'),
                    const SizedBox(height: 16),
                    _buildNewReleases(context),
                    const SizedBox(height: 100), // Space for mini player
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        thickness: 8,
        blur: 4,
        glassColor: Color(0x05FFFFFF),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tunely',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            LiquidGlassButton(
              onPressed: () {},
              borderRadius: 20,
              width: 40,
              height: 40,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeaturedAlbums(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: SongsData.featuredAlbums.length,
        itemBuilder: (context, index) {
          final album = SongsData.featuredAlbums[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildAlbumCard(album, context),
          );
        },
      ),
    );
  }

  Widget _buildAlbumCard(dynamic album, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle album tap
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiquidGlassCard(
              borderRadius: 20,
              blur: 8,
              thickness: 12,
              width: 140,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  album.coverImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              album.artist,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMostPlayed(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: SongsData.songs.take(5).map((song) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LiquidGlassListItem(
                  title: song.title,
                  subtitle: song.artist,
                  imageUrl: song.coverImage,
                  onTap: () {
                    musicProvider.playSong(song);
                  },
                  trailing: Text(
                    song.duration,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildNewReleases(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: SongsData.songs.skip(5).take(5).map((song) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LiquidGlassListItem(
                  title: song.title,
                  subtitle: song.artist,
                  imageUrl: song.coverImage,
                  onTap: () {
                    musicProvider.playSong(song);
                  },
                  trailing: Text(
                    song.duration,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
