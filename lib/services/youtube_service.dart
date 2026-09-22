import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  static const String _searchUrl = 'https://www.youtube.com/results';

  Future<String?> searchVideoId(String trackName, String artistName) async {
    try {
      final query = '$trackName $artistName official';
      final response = await http.get(
        Uri.parse('$_searchUrl?search_query=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        // Extract video ID from YouTube search results
        // This is a simple extraction - in production you might want to use YouTube Data API
        final regex = RegExp(r'\/watch\?v=([a-zA-Z0-9_-]{11})');
        final match = regex.firstMatch(response.body);

        if (match != null) {
          return match.group(1);
        }
      }
    } catch (e) {
      // Silently fail on YouTube search errors
      return null;
    }

    return null;
  }
}