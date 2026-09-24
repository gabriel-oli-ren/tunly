import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config.dart';
import '../domain/music_source.dart';
import '../domain/track.dart';

class ItunesMusicSource implements MusicSource {
  ItunesMusicSource(this._client);
  final http.Client _client;

  @override
  Future<List<Track>> search(String query, {int limit = 25}) async {
    final response = await _get('/search', {
      'term': query,
      'media': 'music',
      'entity': 'song',
      'limit': '$limit',
      'country': 'US',
    });
    return _tracks(response['results']);
  }

  @override
  Future<List<Track>> trending({String country = 'us', int limit = 20}) async {
    // The public Search API has no chart endpoint. Use broad, frequently
    // refreshed catalog queries and de-duplicate their results for discovery.
    final terms = await Future.wait([
      _searchWithCountry('top hits', country, limit ~/ 2 + 2),
      _searchWithCountry('popular music', country, limit ~/ 2 + 2),
    ]);
    final byId = <String, Track>{};
    for (final group in terms) {
      for (final track in group) {
        byId.putIfAbsent(track.id, () => track);
      }
    }
    return byId.values.take(limit).toList(growable: false);
  }

  Future<List<Track>> _searchWithCountry(
      String term, String country, int limit) async {
    final response = await _get('/search', {
      'term': term,
      'media': 'music',
      'entity': 'song',
      'limit': '$limit',
      'country': country.toUpperCase(),
    });
    return _tracks(response['results']);
  }

  @override
  Future<List<Track>> artist(String artistId, {int limit = 25}) async {
    final response = await _get('/lookup', {
      'id': artistId,
      'entity': 'song',
      'limit': '$limit',
    });
    return _tracks(response['results']);
  }

  @override
  Future<List<Track>> album(String albumId, {int limit = 50}) async {
    final response = await _get('/lookup', {
      'id': albumId,
      'entity': 'song',
      'limit': '$limit',
    });
    return _tracks(response['results']);
  }

  @override
  Future<List<Track>> playlist(String playlistId, {int limit = 50}) async =>
      const [];

  @override
  Future<Uri?> resolveStream(Track track) async => null;

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> params) async {
    final base = path == '/lookup'
        ? TunlyConfig.itunesLookupBase
        : TunlyConfig.itunesSearchBase;
    final uri = Uri.parse(base).replace(queryParameters: params);
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw http.ClientException(
          'Music catalog returned ${response.statusCode}', uri);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected catalog response');
    }
    return decoded;
  }

  List<Track> _tracks(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(_track)
        .whereType<Track>()
        .toList(growable: false);
  }

  Track? _track(Map<String, dynamic> item) {
    final trackId = item['trackId'];
    final title = item['trackName'];
    final artist = item['artistName'];
    final artwork = item['artworkUrl100'];
    if (trackId == null ||
        title is! String ||
        artist is! String ||
        artwork is! String) {
      return null;
    }
    final highResArtwork = artwork.replaceFirst('100x100bb', '600x600bb');
    final preview = item['previewUrl'];
    final store = item['trackViewUrl'];
    final rawDate = item['releaseDate'];
    return Track(
      id: '$trackId',
      title: title,
      artist: artist,
      album: item['collectionName'] as String? ?? 'Single',
      artworkUrl: Uri.parse(highResArtwork),
      duration: Duration(
          milliseconds: (item['trackTimeMillis'] as num?)?.toInt() ?? 0),
      previewUrl: preview is String ? Uri.tryParse(preview) : null,
      storeUrl: store is String ? Uri.tryParse(store) : null,
      genre: item['primaryGenreName'] as String?,
      releaseDate: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }
}
