import 'track.dart';

/// Provider boundary for catalog metadata and stream resolution.
/// Implementations can be changed without coupling the UI to an API vendor.
abstract interface class MusicSource {
  Future<List<Track>> search(String query, {int limit = 25});
  Future<List<Track>> trending({String country = 'us', int limit = 20});
  Future<List<Track>> artist(String artistId, {int limit = 25});
  Future<List<Track>> album(String albumId, {int limit = 50});
  Future<List<Track>> playlist(String playlistId, {int limit = 50});
  Future<Uri?> resolveStream(Track track);
}
