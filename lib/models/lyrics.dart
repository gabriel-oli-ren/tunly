class LyricLine {
  final int offset; // in milliseconds
  final String text;

  LyricLine({
    required this.offset,
    required this.text,
  });
}

class Lyrics {
  final List<LyricLine> lines;
  final bool isSynced;

  Lyrics({
    required this.lines,
    required this.isSynced,
  });

  factory Lyrics.fromLrc(String lrcText) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.+)');

    for (final line in lrcText.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final centiseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        final offset = (minutes * 60 + seconds) * 1000 + centiseconds * 10;
        lines.add(LyricLine(offset: offset, text: text));
      }
    }

    lines.sort((a, b) => a.offset.compareTo(b.offset));
    return Lyrics(lines: lines, isSynced: true);
  }

  factory Lyrics.plain(String text) {
    return Lyrics(
      lines: [LyricLine(offset: 0, text: text)],
      isSynced: false,
    );
  }

  LyricLine? getCurrentLine(int currentTimeMs) {
    if (!isSynced || lines.isEmpty) return null;

    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].offset <= currentTimeMs) {
        return lines[i];
      }
    }
    return null;
  }
}