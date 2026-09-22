import 'package:flutter/material.dart';
import '../models/lyrics.dart';

class LyricsWidget extends StatelessWidget {
  final Lyrics? lyrics;
  final double currentPosition;

  const LyricsWidget({
    super.key,
    required this.lyrics,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (lyrics == null || lyrics!.lines.isEmpty) {
      return Center(
        child: Text(
          'No lyrics available',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
        ),
      );
    }

    if (!lyrics!.isSynced) {
      // Plain lyrics display
      return Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            lyrics!.lines.first.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Synced lyrics display
    final currentTimeMs = (currentPosition * 1000).toInt();
    final currentLine = lyrics!.getCurrentLine(currentTimeMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: lyrics!.lines.length,
        itemBuilder: (context, index) {
          final line = lyrics!.lines[index];
          final isCurrentLine = currentLine?.text == line.text;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              line.text,
              style: TextStyle(
                color: isCurrentLine ? Colors.white : Colors.grey[500],
                fontSize: isCurrentLine ? 20 : 16,
                fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}