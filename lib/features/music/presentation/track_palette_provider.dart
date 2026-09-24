import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../app/theme.dart';
import '../domain/track.dart';

final trackPaletteProvider = FutureProvider.family<Color, Track>((
  ref,
  track,
) async {
  try {
    final palette = await PaletteGenerator.fromImageProvider(
      NetworkImage(track.artworkUrl.toString()),
      size: const Size(96, 96),
      maximumColorCount: 8,
    ).timeout(const Duration(seconds: 4));
    return palette.dominantColor?.color ?? TunlyTheme.elevated;
  } catch (_) {
    return TunlyTheme.elevated;
  }
});
