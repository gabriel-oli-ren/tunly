class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artworkUrl;
  final String? youtubeVideoId;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    this.youtubeVideoId,
  });

  factory Song.fromITunesJson(Map<String, dynamic> json) {
    String artworkUrl = json['artworkUrl100'] ?? '';
    // Swap 100x100 for 600x600 for high-res artwork
    artworkUrl = artworkUrl.replaceAll('100x100', '600x600');

    return Song(
      id: json['trackId'].toString(),
      title: json['trackName'] ?? 'Unknown',
      artist: json['artistName'] ?? 'Unknown',
      album: json['collectionName'] ?? 'Unknown',
      artworkUrl: artworkUrl,
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    String? youtubeVideoId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
    );
  }
}