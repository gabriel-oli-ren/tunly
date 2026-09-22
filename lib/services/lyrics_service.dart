import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lyrics.dart';

class LyricsService {
  static const String _baseUrl = 'https://lrclib.net/api/search';

  Future<Lyrics?> searchLyrics(String trackName, String artistName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?track_name=${Uri.encodeComponent(trackName)}&artist_name=${Uri.encodeComponent(artistName)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        if (data.isEmpty) return null;

        // Try to find synced lyrics first
        for (final item in data) {
          if (item['syncedLyrics'] != null && item['syncedLyrics'].isNotEmpty) {
            return Lyrics.fromLrc(item['syncedLyrics']);
          }
        }

        // Fallback to plain lyrics
        for (final item in data) {
          if (item['plainLyrics'] != null && item['plainLyrics'].isNotEmpty) {
            return Lyrics.plain(item['plainLyrics']);
          }
        }

        return null;
      }
    } catch (e) {
      // Silently fail on lyrics errors
      return null;
    }

    return null;
  }
}