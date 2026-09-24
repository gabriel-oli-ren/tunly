import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import '../../music/domain/track.dart';
import 'video_match.dart';

/// Looks up candidate video IDs through Piped's public search API.
/// Playback itself stays inside YouTube's official embedded player.
class YoutubeVideoResolver {
  YoutubeVideoResolver(this._client);
  final http.Client _client;
  final Map<String, ({DateTime expires, List<Track> tracks})> _trendCache = {};

  Future<List<VideoMatch>> resolve(
    Track track, {
    void Function()? onFallback,
  }) async {
    final directId = track.youtubeVideoId;
    if (directId != null && RegExp(r'^[\w-]{11}$').hasMatch(directId)) {
      return [
        VideoMatch(
          videoId: directId,
          title: track.title,
          channel: track.artist,
          duration: track.duration,
        ),
      ];
    }
    final query = '${track.artist} ${track.title} official audio';
    Object? lastError;

    for (var index = 0; index < TunlyConfig.pipedInstances.length; index++) {
      if (index > 0) onFallback?.call();
      final instance = TunlyConfig.pipedInstances[index];
      try {
        final uri = Uri.parse(
          '$instance/search',
        ).replace(queryParameters: {'q': query, 'filter': 'videos'});
        final response = await _client
            .get(uri, headers: const {'accept': 'application/json'})
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          throw http.ClientException(
            'Search source returned ${response.statusCode}',
            uri,
          );
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is! Map<String, dynamic> || body['items'] is! List) {
          throw const FormatException('Unexpected video search response');
        }
        final matches = (body['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => _parse(item))
            .whereType<VideoMatch>()
            .toList(growable: false);
        final ranked = _rank(track, matches).take(5).toList(growable: false);
        if (ranked.isNotEmpty) return ranked;
        lastError = StateError('No close video match at $instance');
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('All video search sources are unavailable: $lastError');
  }

  /// Matches regional YouTube charts to iTunes song metadata so the feed only
  /// promotes music while playing the exact video currently trending there.
  Future<List<Track>> trendingTracks({
    required String country,
    required List<Track> regionalSongs,
  }) async {
    final key = country.toUpperCase();
    final cached = _trendCache[key];
    if (cached != null && cached.expires.isAfter(DateTime.now())) {
      return cached.tracks;
    }
    Object? lastError;
    for (final instance in TunlyConfig.pipedInstances) {
      try {
        final uri = Uri.parse(
          '$instance/trending',
        ).replace(queryParameters: {'region': key});
        final response = await _client
            .get(uri, headers: const {'accept': 'application/json'})
            .timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          throw http.ClientException(
            'Trending source returned ${response.statusCode}',
            uri,
          );
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is! List) {
          throw const FormatException('Unexpected trending response');
        }
        final videos = body.whereType<Map<String, dynamic>>().toList();
        final matched = <Track>[];
        final usedTracks = <String>{};
        for (final video in videos) {
          final videoId = _videoId(video['url']);
          final title = video['title'];
          final thumbnail = video['thumbnail'];
          final durationSeconds = (video['duration'] as num?)?.toInt() ?? 0;
          if (videoId == null ||
              title is! String ||
              thumbnail is! String ||
              durationSeconds < 45 ||
              durationSeconds > 900 ||
              video['isShort'] == true) {
            continue;
          }
          final channel = video['uploaderName'] as String? ?? '';
          final candidateTokens = _tokens('$title $channel');
          Track? best;
          var bestScore = 0.0;
          for (final song in regionalSongs) {
            if (usedTracks.contains(song.id)) continue;
            final titleTokens = _tokens(song.title);
            final artistTokens = _tokens(song.artist);
            final titleMatch = _coverage(titleTokens, candidateTokens);
            final artistMatch = _coverage(artistTokens, candidateTokens);
            if (titleMatch < .5 || artistMatch < .25) continue;
            final score = titleMatch * 2 + artistMatch;
            if (score > bestScore) {
              best = song;
              bestScore = score;
            }
          }
          if (best == null) continue;
          usedTracks.add(best.id);
          matched.add(best.withYoutubeVideoId(videoId));
          if (matched.length == 12) break;
        }
        final result = List<Track>.unmodifiable(matched);
        _trendCache[key] = (
          expires: DateTime.now().add(const Duration(minutes: 8)),
          tracks: result,
        );
        return result;
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Regional YouTube charts are unavailable: $lastError');
  }

  String? _videoId(Object? value) {
    if (value is! String) return null;
    final raw = value.trim();
    if (RegExp(r'^[\w-]{11}$').hasMatch(raw)) return raw;
    final uri = Uri.tryParse(
      raw.startsWith('/') ? 'https://www.youtube.com$raw' : raw,
    );
    final host = uri?.host.toLowerCase();
    final segments = uri?.pathSegments ?? const <String>[];
    final id = host == 'youtu.be'
        ? (segments.isEmpty ? null : segments.first)
        : uri?.queryParameters['v'] ??
              (segments.length >= 2 &&
                      {'embed', 'shorts', 'live'}.contains(segments.first)
                  ? segments[1]
                  : null);
    return id != null && RegExp(r'^[\w-]{11}$').hasMatch(id) ? id : null;
  }

  double _coverage(Set<String> expected, Set<String> actual) => expected.isEmpty
      ? 0
      : expected.where(actual.contains).length / expected.length;

  VideoMatch? _parse(Map<String, dynamic> item) {
    final title = item['title'];
    final uploader = item['uploaderName'];
    final url = item['url'];
    if (title is! String || url is! String) return null;
    final videoId = _videoId(url);
    if (videoId == null || !RegExp(r'^[\w-]{11}$').hasMatch(videoId)) {
      return null;
    }
    final seconds = (item['duration'] as num?)?.toInt() ?? 0;
    return VideoMatch(
      videoId: videoId,
      title: title,
      channel: uploader is String ? uploader : '',
      duration: Duration(seconds: seconds),
    );
  }

  List<VideoMatch> _rank(Track track, List<VideoMatch> matches) {
    final titleTokens = _tokens(track.title);
    final artistTokens = _tokens(track.artist);
    final targetDuration = track.duration.inSeconds;
    final scored = <({VideoMatch match, double score})>[];
    for (final match in matches) {
      final videoTitle = _tokens(match.title);
      final videoChannel = _tokens(match.channel);
      final combined = {...videoTitle, ...videoChannel};
      final titleCoverage = titleTokens.isEmpty
          ? 0.0
          : titleTokens.where(combined.contains).length / titleTokens.length;
      final artistCoverage = artistTokens.isEmpty
          ? 0.0
          : artistTokens.where(combined.contains).length / artistTokens.length;
      if (titleCoverage < .5 || artistCoverage < .35) continue;

      var score = titleCoverage * 6 + artistCoverage * 4;
      if (match.title.toLowerCase().contains(track.title.toLowerCase())) {
        score += 1.2;
      }
      if (match.channel.toLowerCase().contains(track.artist.toLowerCase())) {
        score += 1.4;
      }
      if (targetDuration > 0 && match.duration.inSeconds > 0) {
        final difference = (targetDuration - match.duration.inSeconds).abs();
        if (difference > 120) continue;
        score -= difference / 60;
      }
      scored.add((match: match, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((entry) => entry.match).toList(growable: false);
  }

  Set<String> _tokens(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\([^)]*\)|\[[^\]]*\]'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .split(' ')
      .where((word) => word.length > 1 && !_ignored.contains(word))
      .toSet();

  static const _ignored = {
    'the',
    'and',
    'feat',
    'featuring',
    'official',
    'audio',
    'video',
    'lyrics',
    'topic',
    'hd',
    'hq',
  };
}
