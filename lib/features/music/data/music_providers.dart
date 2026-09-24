import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/music_source.dart';
import '../domain/track.dart';
import '../../player/data/youtube_video_resolver.dart';
import 'music_region.dart';
import 'itunes_music_source.dart';

final musicSourceProvider = Provider<MusicSource>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ItunesMusicSource(client);
});

final youtubeVideoResolverProvider = Provider<YoutubeVideoResolver>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return YoutubeVideoResolver(client);
});

final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final source = ref.watch(musicSourceProvider);
  final region = ref.watch(musicRegionProvider);
  final lists = await Future.wait([
    _keepGoing(source.trending(country: region.countryCode, limit: 30)),
    _keepGoing(source.search('new music', limit: 16)),
    _keepGoing(source.search('chill hits', limit: 16)),
  ]);
  var trending = lists[0];
  var fromYouTube = false;
  try {
    final regionalVideos = await ref
        .read(youtubeVideoResolverProvider)
        .trendingTracks(country: region.countryCode, regionalSongs: trending);
    if (regionalVideos.isNotEmpty) {
      trending = regionalVideos;
      fromYouTube = true;
    }
  } catch (_) {
    // Keep the country-specific iTunes chart available if Piped is down.
  }
  return HomeFeed(
    trending: trending,
    newReleases: lists[1],
    madeForYou: lists[2],
    regionName: region.countryName,
    trendingSource: fromYouTube ? 'YouTube' : 'iTunes charts',
  );
});

final searchResultsProvider = FutureProvider.family<List<Track>, String>((
  ref,
  query,
) async {
  if (query.trim().length < 2) return const [];
  return ref.watch(musicSourceProvider).search(query.trim(), limit: 30);
});

Future<List<Track>> _keepGoing(Future<List<Track>> request) async {
  try {
    return await request;
  } catch (_) {
    return const [];
  }
}

class HomeFeed {
  const HomeFeed({
    required this.trending,
    required this.newReleases,
    required this.madeForYou,
    required this.regionName,
    required this.trendingSource,
  });
  final List<Track> trending;
  final List<Track> newReleases;
  final List<Track> madeForYou;
  final String regionName;
  final String trendingSource;
}
