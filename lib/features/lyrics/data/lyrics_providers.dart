import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../library/data/library_providers.dart';
import '../../music/domain/track.dart';
import '../domain/lyrics.dart';
import 'lrclib_repository.dart';

final lyricsRepositoryProvider = Provider<LrclibRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return LrclibRepository(client, ref.watch(localLibraryProvider));
});

final lyricsProvider = FutureProvider.family<Lyrics?, Track>(
  (ref, track) => ref.watch(lyricsRepositoryProvider).lyricsFor(track),
);
