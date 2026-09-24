class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    required this.duration,
    this.previewUrl,
    this.storeUrl,
    this.genre,
    this.releaseDate,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Uri artworkUrl;
  final Duration duration;
  final Uri? previewUrl;
  final Uri? storeUrl;
  final String? genre;
  final DateTime? releaseDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl.toString(),
        'durationMs': duration.inMilliseconds,
        'previewUrl': previewUrl?.toString(),
        'storeUrl': storeUrl?.toString(),
        'genre': genre,
        'releaseDate': releaseDate?.toIso8601String(),
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        album: json['album'] as String,
        artworkUrl: Uri.parse(json['artworkUrl'] as String),
        duration:
            Duration(milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0),
        previewUrl: json['previewUrl'] is String
            ? Uri.tryParse(json['previewUrl'] as String)
            : null,
        storeUrl: json['storeUrl'] is String
            ? Uri.tryParse(json['storeUrl'] as String)
            : null,
        genre: json['genre'] as String?,
        releaseDate: json['releaseDate'] is String
            ? DateTime.tryParse(json['releaseDate'] as String)
            : null,
      );
}

class Artist {
  const Artist({required this.id, required this.name, this.artworkUrl});
  final String id;
  final String name;
  final Uri? artworkUrl;
}

class Album {
  const Album(
      {required this.id,
      required this.title,
      required this.artist,
      this.artworkUrl});
  final String id;
  final String title;
  final String artist;
  final Uri? artworkUrl;
}

class MusicPlaylist {
  const MusicPlaylist(
      {required this.id, required this.title, this.description});
  final String id;
  final String title;
  final String? description;
}
