import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';

/// Cover for a playlist, built from the covers of the Pirith inside it.
///
/// Empty playlist → the same placeholder a coverless Pirith gets, keyed on
/// the playlist id so it keeps one identity. One to three items → the first
/// item's cover (a collage of two reads as a mistake). Four or more → a 2×2
/// grid of the first four, which is the familiar playlist idiom.
///
/// Covers always come from the square app artwork (`coverUrl`), never the
/// 16:9 YouTube thumbnail.
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({
    required this.playlistId,
    required this.coverUrls,
    this.size = 56,
    this.radius = AppRadius.md,
    super.key,
  });

  final String playlistId;

  /// Cover URLs of the playlist's Pirith, in playlist order. Entries may be
  /// empty strings — [PirithArtwork] falls back to its placeholder.
  final List<String> coverUrls;

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (coverUrls.length < 4) {
      return PirithArtwork(
        pirithId: playlistId,
        coverUrl: coverUrls.isEmpty ? '' : coverUrls.first,
        size: size,
        radius: radius,
      );
    }

    final tile = size / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          children: [
            Row(children: [_tile(0, tile), _tile(1, tile)]),
            Row(children: [_tile(2, tile), _tile(3, tile)]),
          ],
        ),
      ),
    );
  }

  /// Square corners on the quadrants — the outer [ClipRRect] supplies the
  /// rounding, so rounding each tile too would leave gaps at the seams.
  Widget _tile(int index, double tile) => PirithArtwork(
    pirithId: '$playlistId-$index',
    coverUrl: coverUrls[index],
    size: tile,
    radius: 0,
  );
}
