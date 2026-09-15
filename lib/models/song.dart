class Song {
  final int id;
  final String title;
  final String artist;
  final String coverImage;
  final String youtubeId;
  final String duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverImage,
    required this.youtubeId,
    required this.duration,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      coverImage: json['coverImage'],
      youtubeId: json['youtubeId'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'coverImage': coverImage,
      'youtubeId': youtubeId,
      'duration': duration,
    };
  }
}

class Album {
  final int id;
  final String title;
  final String artist;
  final String coverImage;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverImage,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      coverImage: json['coverImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'coverImage': coverImage,
    };
  }
}
