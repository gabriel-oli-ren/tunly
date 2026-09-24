class LyricLine {
  const LyricLine({required this.time, required this.text});
  final Duration time;
  final String text;
}

class Lyrics {
  const Lyrics(
      {required this.lines, required this.plainText, required this.synced});
  final List<LyricLine> lines;
  final String plainText;
  final bool synced;
}
