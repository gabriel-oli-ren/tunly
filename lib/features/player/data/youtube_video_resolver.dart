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

  Future<List<VideoMatch>> resolve(Track track) async {
    final query = '${track.artist} ${track.title} official audio';
    Object? lastError;

    for (final instance in TunlyConfig.pipedInstances) {
      try {
        final uri = Uri.parse('$instance/search').replace(queryParameters: {
          'q': query,
          'filter': 'videos',
        });
        final response = await _client.get(uri, headers: const {
          'accept': 'application/json'
        }).timeout(const Duration(seconds: 7));
        if (response.statusCode != 200) {
          throw http.ClientException(
              'Search source returned ${response.statusCode}', uri);
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
        return _rank(track, matches).take(5).toList(growable: false);
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('All video search sources are unavailable: $lastError');
  }

  VideoMatch? _parse(Map<String, dynamic> item) {
    final title = item['title'];
    final uploader = item['uploaderName'];
    final url = item['url'];
    if (title is! String || url is! String) return null;
    final parsed = Uri.tryParse(url);
    final videoId = parsed?.queryParameters['v'];
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
    'hq'
  };
}
