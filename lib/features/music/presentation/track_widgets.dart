import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../domain/track.dart';
import '../../player/presentation/now_playing_sheet.dart';

Future<void> openTrackStore(Track track) async {
  final uri = track.storeUrl;
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({required this.track, this.size = 64, super.key});
  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * .17),
        child: Image.network(
          track.artworkUrl.toString(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, _) => frame == null
              ? Container(
                  width: size,
                  height: size,
                  color: TunlyTheme.elevated,
                  child: const CupertinoActivityIndicator())
              : child,
          errorBuilder: (context, error, stack) => Container(
            width: size,
            height: size,
            color: TunlyTheme.elevated,
            child: const Icon(CupertinoIcons.music_note,
                color: TunlyTheme.secondaryText),
          ),
        ),
      );
}

class TrackRow extends StatelessWidget {
  const TrackRow({required this.track, this.onTap, super.key});
  final Track track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          TrackArtwork(track: track, size: 56),
          const SizedBox(width: 13),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: onTap ?? () => presentTrackPlayer(context, track),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${track.artist} · ${track.album}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: TunlyTheme.secondaryText)),
                  ]),
            ),
          ),
          const SizedBox(width: 10),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(34, 34),
            onPressed:
                track.storeUrl == null ? null : () => openTrackStore(track),
            child: const Icon(CupertinoIcons.arrow_up_right,
                color: TunlyTheme.secondaryText, size: 17),
          ),
        ]),
      );
}

class TrackCarousel extends StatelessWidget {
  const TrackCarousel({required this.tracks, this.onTrackTap, super.key});
  final List<Track> tracks;
  final ValueChanged<Track>? onTrackTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 206,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: tracks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final track = tracks[index];
            return SizedBox(
              width: 142,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (onTrackTap != null) {
                    onTrackTap!(track);
                  } else {
                    presentTrackPlayer(context, track, queue: tracks);
                  }
                },
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackArtwork(track: track, size: 142),
                      const SizedBox(height: 9),
                      Text(track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: TunlyTheme.secondaryText)),
                    ]),
              ),
            );
          },
        ),
      );
}
