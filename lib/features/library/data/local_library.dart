import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../music/domain/track.dart';

class LocalPlaylist {
  const LocalPlaylist({
    required this.id,
    required this.name,
    required this.tracks,
  });
  final String id;
  final String name;
  final List<Track> tracks;

  Map<String, dynamic> toJson() => {
    'name': name,
    'tracks': tracks.map((track) => track.toJson()).toList(),
  };

  factory LocalPlaylist.fromEntry(String id, String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final tracks = (json['tracks'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Track.fromJson)
        .toList(growable: false);
    return LocalPlaylist(
      id: id,
      name: json['name'] as String? ?? 'Playlist',
      tracks: tracks,
    );
  }
}

class LocalLibrary {
  LocalLibrary(this._box);
  final Box<String> _box;

  Future<List<Track>> likedTracks() async => _tracks('liked:');
  Future<List<Track>> listeningHistory() async => _tracks('history:');

  Future<List<String>> recentSearches() async {
    final raw = _box.get('recent_searches');
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded.whereType<String>().toList(growable: false)
        : const [];
  }

  Future<void> rememberSearch(String query) async {
    final current = await recentSearches();
    final updated = [
      query,
      ...current.where((item) => item.toLowerCase() != query.toLowerCase()),
    ].take(8).toList();
    await _box.put('recent_searches', jsonEncode(updated));
  }

  Future<void> clearSearches() => _box.delete('recent_searches');

  Future<void> toggleLiked(Track track) async {
    final key = 'liked:${track.id}';
    if (_box.containsKey(key)) {
      await _box.delete(key);
    } else {
      await _box.put(key, jsonEncode(track.toJson()));
    }
  }

  Future<void> recordListen(Track track) async {
    final key = 'history:${DateTime.now().microsecondsSinceEpoch}';
    await _box.put(key, jsonEncode(track.toJson()));
    final keys =
        _box.keys
            .whereType<String>()
            .where((key) => key.startsWith('history:'))
            .toList()
          ..sort();
    if (keys.length > 100) {
      for (final oldKey in keys.take(keys.length - 100)) {
        await _box.delete(oldKey);
      }
    }
  }

  Future<List<LocalPlaylist>> playlists() async {
    final entries =
        _box
            .toMap()
            .entries
            .where(
              (entry) =>
                  entry.key is String && entry.key.startsWith('playlist:'),
            )
            .toList()
          ..sort((a, b) => (a.value).compareTo(b.value));
    return entries
        .map((entry) => LocalPlaylist.fromEntry(entry.key, entry.value))
        .toList(growable: false);
  }

  Future<LocalPlaylist> createPlaylist(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final playlist = LocalPlaylist(id: id, name: name.trim(), tracks: const []);
    await _savePlaylist(playlist);
    return playlist;
  }

  Future<void> renamePlaylist(LocalPlaylist playlist, String name) =>
      _savePlaylist(
        LocalPlaylist(
          id: playlist.id,
          name: name.trim(),
          tracks: playlist.tracks,
        ),
      );

  Future<void> deletePlaylist(String id) => _box.delete('playlist:$id');

  Future<void> addToPlaylist(LocalPlaylist playlist, Track track) async {
    if (playlist.tracks.any((item) => item.id == track.id)) return;
    await _savePlaylist(
      LocalPlaylist(
        id: playlist.id,
        name: playlist.name,
        tracks: [...playlist.tracks, track],
      ),
    );
  }

  Future<void> removeFromPlaylist(LocalPlaylist playlist, Track track) =>
      _savePlaylist(
        LocalPlaylist(
          id: playlist.id,
          name: playlist.name,
          tracks: playlist.tracks.where((item) => item.id != track.id).toList(),
        ),
      );

  Future<void> reorderPlaylist(LocalPlaylist playlist, int from, int to) async {
    final tracks = [...playlist.tracks];
    final track = tracks.removeAt(from);
    tracks.insert(to, track);
    await _savePlaylist(
      LocalPlaylist(id: playlist.id, name: playlist.name, tracks: tracks),
    );
  }

  Future<String?> cachedLyrics(String trackId) async =>
      _box.get('lyrics:$trackId');
  Future<void> cacheLyrics(String trackId, String json) =>
      _box.put('lyrics:$trackId', json);

  String? setting(String key) => _box.get('setting:$key');

  Future<void> setSetting(String key, String value) =>
      _box.put('setting:$key', value);

  Future<void> _savePlaylist(LocalPlaylist playlist) =>
      _box.put('playlist:${playlist.id}', jsonEncode(playlist.toJson()));

  Future<List<Track>> _tracks(String prefix) async {
    final entries =
        _box
            .toMap()
            .entries
            .where(
              (entry) => entry.key is String && entry.key.startsWith(prefix),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return entries.reversed
        .map(
          (entry) =>
              Track.fromJson(jsonDecode(entry.value) as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
