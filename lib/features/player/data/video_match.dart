class VideoMatch {
  const VideoMatch({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.duration,
  });

  final String videoId;
  final String title;
  final String channel;
  final Duration duration;
}
