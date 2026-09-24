import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../music/domain/track.dart';
import 'local_library.dart';

final localLibraryProvider = Provider<LocalLibrary>(
    (ref) => LocalLibrary(Hive.box<String>('tunly_local')));
final likedTracksProvider = FutureProvider<List<Track>>(
    (ref) => ref.watch(localLibraryProvider).likedTracks());
final listeningHistoryProvider = FutureProvider<List<Track>>(
    (ref) => ref.watch(localLibraryProvider).listeningHistory());
final localPlaylistsProvider = FutureProvider<List<LocalPlaylist>>(
    (ref) => ref.watch(localLibraryProvider).playlists());
final recentSearchesProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(localLibraryProvider).recentSearches());
