import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, ReorderableListView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/presentation/native_cupertino_controls.dart';
import '../../music/presentation/track_widgets.dart';
import '../../music/domain/track.dart';
import '../../player/presentation/now_playing_sheet.dart';
import '../data/library_providers.dart';
import '../data/local_library.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _section = 'Playlists';

  Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('New playlist'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Playlist name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await ref.read(localLibraryProvider).createPlaylist(name);
    ref.invalidate(localPlaylistsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final liked = ref.watch(likedTracksProvider);
    final history = ref.watch(listeningHistoryProvider);
    final playlists = ref.watch(localPlaylistsProvider);
    final artists = <String, Track>{};
    for (final track in [
      ...(liked.valueOrNull ?? const <Track>[]),
      ...(history.valueOrNull ?? const <Track>[]),
      ...(playlists.valueOrNull?.expand((playlist) => playlist.tracks) ??
          const <Track>[]),
    ]) {
      artists.putIfAbsent(track.artist, () => track);
    }
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverNavigationBar(
          transitionBetweenRoutes: false,
          largeTitle: const Text('Your Library'),
          border: null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => context.go('/search'),
                child: const Icon(CupertinoIcons.search, size: 20),
              ),
              TunlyAddButton(onPressed: () => _createPlaylist(context, ref)),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 210),
          sliver: SliverList.list(
            children: [
              TunlySegmentedControl(
                labels: const ['Playlists', 'Artists', 'Liked', 'History'],
                selectedIndex: const [
                  'Playlists',
                  'Artists',
                  'Liked',
                  'History',
                ].indexOf(_section),
                onChanged: (value) {
                  setState(
                    () => _section = const [
                      'Playlists',
                      'Artists',
                      'Liked',
                      'History',
                    ][value],
                  );
                },
              ),
              const SizedBox(height: 22),
              if (_section == 'Playlists') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle('Your playlists'),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _createPlaylist(context, ref),
                      child: const Text('New'),
                    ),
                  ],
                ),
                playlists.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (error, stack) => const _EmptyNote(
                    'Your playlists are temporarily unavailable.',
                  ),
                  data: (items) => items.isEmpty
                      ? const _EmptyNote(
                          'Your playlists will appear here after you create one.',
                        )
                      : Column(
                          children: items
                              .map(
                                (playlist) => _PlaylistRow(playlist: playlist),
                              )
                              .toList(),
                        ),
                ),
              ] else if (_section == 'Artists') ...[
                const _SectionTitle('Artists you saved'),
                if (artists.isEmpty)
                  const _EmptyNote(
                    'Save a song or add one to a playlist to see its artist here.',
                  )
                else
                  ...artists.entries.map(
                    (entry) => _ArtistRow(
                      name: entry.key,
                      track: entry.value,
                      onTap: () => context.go(
                        '/search?q=${Uri.encodeQueryComponent(entry.key)}',
                      ),
                    ),
                  ),
              ] else if (_section == 'Liked') ...[
                const _SectionTitle('Liked songs'),
                liked.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (error, stack) => const _EmptyNote(
                    'Your saved songs are temporarily unavailable.',
                  ),
                  data: (tracks) => tracks.isEmpty
                      ? const _EmptyNote('Songs you like will appear here.')
                      : Column(
                          children: tracks
                              .take(100)
                              .map(
                                (track) => TrackRow(
                                  track: track,
                                  onTap: () => presentTrackPlayer(
                                    context,
                                    track,
                                    queue: tracks,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ] else ...[
                const _SectionTitle('Recently played'),
                history.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (error, stack) => const _EmptyNote(
                    'Listening history is temporarily unavailable.',
                  ),
                  data: (tracks) => tracks.isEmpty
                      ? const _EmptyNote('Tracks you open will show up here.')
                      : Column(
                          children: tracks
                              .take(100)
                              .map(
                                (track) => TrackRow(
                                  track: track,
                                  onTap: () => presentTrackPlayer(
                                    context,
                                    track,
                                    queue: tracks,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Your library stays on this device.',
                style: TextStyle(color: TunlyTheme.secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: const TextStyle(color: TunlyTheme.secondaryText, fontSize: 14),
    ),
  );
}

class _ArtistRow extends StatelessWidget {
  const _ArtistRow({
    required this.name,
    required this.track,
    required this.onTap,
  });

  final String name;
  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Row(
        children: [
          ClipOval(child: TrackArtwork(track: track, size: 58)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: TunlyTheme.secondaryText,
          ),
        ],
      ),
    ),
  );
}

class _PlaylistRow extends ConsumerWidget {
  const _PlaylistRow({required this.playlist});
  final LocalPlaylist playlist;

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(playlist.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'rename'),
            child: const Text('Rename'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete playlist'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (choice == 'delete') {
      await ref.read(localLibraryProvider).deletePlaylist(playlist.id);
      ref.invalidate(localPlaylistsProvider);
    } else if (choice == 'rename' && context.mounted) {
      final controller = TextEditingController(text: playlist.name);
      final name = await showCupertinoDialog<String>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Rename playlist'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: CupertinoTextField(controller: controller, autofocus: true),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (name != null && name.trim().isNotEmpty) {
        await ref.read(localLibraryProvider).renamePlaylist(playlist, name);
        ref.invalidate(localPlaylistsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showCupertinoModalPopup<void>(
            context: context,
            builder: (_) => _PlaylistDetail(playlist: playlist),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: TunlyTheme.elevated,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: playlist.tracks.isEmpty
                    ? const Icon(
                        CupertinoIcons.music_note_list,
                        color: TunlyTheme.accent,
                      )
                    : TrackArtwork(track: playlist.tracks.first, size: 56),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.tracks.length} songs',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TunlyTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () => _showActions(context, ref),
          child: const Icon(
            CupertinoIcons.ellipsis,
            color: TunlyTheme.secondaryText,
          ),
        ),
      ],
    ),
  );
}

class _PlaylistDetail extends ConsumerStatefulWidget {
  const _PlaylistDetail({required this.playlist});
  final LocalPlaylist playlist;
  @override
  ConsumerState<_PlaylistDetail> createState() => _PlaylistDetailState();
}

class _PlaylistDetailState extends ConsumerState<_PlaylistDetail> {
  late List<Track> tracks;
  @override
  void initState() {
    super.initState();
    tracks = [...widget.playlist.tracks];
  }

  Future<void> _reorder(int from, int to) async {
    final item = tracks.removeAt(from);
    tracks.insert(to, item);
    setState(() {});
    final current = LocalPlaylist(
      id: widget.playlist.id,
      name: widget.playlist.name,
      tracks: tracks,
    );
    await ref.read(localLibraryProvider).reorderPlaylist(current, from, to);
    ref.invalidate(localPlaylistsProvider);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF111216),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.playlist.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill),
                  ),
                ],
              ),
            ),
            if (tracks.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Add songs from Now Playing.',
                    style: TextStyle(color: TunlyTheme.secondaryText),
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: tracks.length,
                  onReorderItem: _reorder,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Container(
                      key: ValueKey(track.id),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: TrackRow(
                              track: track,
                              onTap: () => presentTrackPlayer(
                                context,
                                track,
                                queue: tracks,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.all(8),
                            onPressed: () async {
                              final current = LocalPlaylist(
                                id: widget.playlist.id,
                                name: widget.playlist.name,
                                tracks: tracks,
                              );
                              await ref
                                  .read(localLibraryProvider)
                                  .removeFromPlaylist(current, track);
                              setState(() => tracks.removeAt(index));
                              ref.invalidate(localPlaylistsProvider);
                            },
                            child: const Icon(
                              CupertinoIcons.minus_circle,
                              color: TunlyTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
