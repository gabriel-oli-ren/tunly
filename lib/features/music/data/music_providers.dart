import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/music_source.dart';
import '../domain/track.dart';
import '../../player/data/youtube_video_resolver.dart';
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
  final lists = await Future.wait([
    _keepGoing(source.trending(limit: 16)),
    _keepGoing(source.search('new music', limit: 16)),
    _keepGoing(source.search('chill hits', limit: 16)),
  ]);
  return HomeFeed(
      trending: lists[0], newReleases: lists[1], madeForYou: lists[2]);
});

final searchResultsProvider =
    FutureProvider.family<List<Track>, String>((ref, query) async {
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
  const HomeFeed(
      {required this.trending,
      required this.newReleases,
      required this.madeForYou});
  final List<Track> trending;
  final List<Track> newReleases;
  final List<Track> madeForYou;
}
