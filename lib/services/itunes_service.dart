import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class ITunesService {
  static const String _baseUrl = 'https://itunes.apple.com/search';

  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl?term=${Uri.encodeComponent(query)}&entity=song&limit=20'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      return results.map((json) => Song.fromITunesJson(json)).toList();
    } else {
      throw Exception('Failed to search songs: ${response.statusCode}');
    }
  }
}