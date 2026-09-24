import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import '../../library/data/local_library.dart';
import '../../music/domain/track.dart';
import '../domain/lyrics.dart';

class LrclibRepository {
  LrclibRepository(this._client, this._library);
  final http.Client _client;
  final LocalLibrary _library;

  Future<Lyrics?> lyricsFor(Track track) async {
    final cached = await _library.cachedLyrics(track.id);
    if (cached != null) {
      return _parse(jsonDecode(cached) as Map<String, dynamic>);
    }

    final base = Uri.parse(TunlyConfig.lrclibApiBase);
    final headers = const {
      'accept': 'application/json',
      'X-User-Agent': 'Tunly/1.0 (https://tunly.app)',
    };
    final exactUri = base.replace(queryParameters: {
      'artist_name': track.artist,
      'track_name': track.title,
      'album_name': track.album,
      'duration': '${track.duration.inSeconds}',
    });
    final exact = await _get(exactUri, headers);
    if (exact != null) {
      await _library.cacheLyrics(track.id, jsonEncode(exact));
      return _parse(exact);
    }

    final searchUri =
        base.replace(path: '${base.path}/search', queryParameters: {
      'artist_name': track.artist,
      'track_name': track.title,
    });
    final search = await _get(searchUri, headers);
    if (search == null) {
      return null;
    }
    final records = search['records'];
    if (records is! List ||
        records.isEmpty ||
        records.first is! Map<String, dynamic>) {
      return null;
    }
    final match = records.first as Map<String, dynamic>;
    await _library.cacheLyrics(track.id, jsonEncode(match));
    return _parse(match);
  }

  Future<Map<String, dynamic>?> _get(
      Uri uri, Map<String, String> headers) async {
    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw http.ClientException(
          'Lyrics service returned ${response.statusCode}', uri);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return {'records': decoded};
    return null;
  }

  Lyrics? _parse(Map<String, dynamic> record) {
    final syncedText = record['syncedLyrics'] as String?;
    final plainText = record['plainLyrics'] as String? ?? '';
    final syncedLines =
        syncedText == null ? <LyricLine>[] : _parseSynced(syncedText);
    final text = syncedLines.isNotEmpty
        ? syncedLines.map((line) => line.text).join('\n')
        : plainText;
    if (text.trim().isEmpty) return null;
    return Lyrics(
        lines: syncedLines, plainText: text, synced: syncedLines.isNotEmpty);
  }

  List<LyricLine> _parseSynced(String lrc) {
    final lines = <LyricLine>[];
    final stamp = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
    for (final row in const LineSplitter().convert(lrc)) {
      final matches = stamp.allMatches(row).toList();
      if (matches.isEmpty) continue;
      final text = row.substring(matches.last.end).trim();
      if (text.isEmpty) continue;
      for (final match in matches) {
        final minutes = int.tryParse(match.group(1)!) ?? 0;
        final seconds = int.tryParse(match.group(2)!) ?? 0;
        final fractions = match.group(3) ?? '';
        final milliseconds = fractions.isEmpty
            ? 0
            : int.parse(fractions.padRight(3, '0').substring(0, 3));
        lines.add(LyricLine(
            time: Duration(
                minutes: minutes, seconds: seconds, milliseconds: milliseconds),
            text: text));
      }
    }
    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
