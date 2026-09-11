import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/pirith_mark.dart';

/// Cover art for a Pirith: the real uploaded image when there is one,
/// otherwise a colored placeholder with the dhamma-wheel mark.
///
/// The placeholder color is derived from [pirithId] rather than the item's
/// position in whichever list is rendering it, so a Pirith without cover art
/// still looks the same everywhere it appears. A broken or slow image URL
/// falls back to that same placeholder rather than a grey box or a crash.
class PirithArtwork extends StatelessWidget {
  const PirithArtwork({
    required this.pirithId,
    this.coverUrl = '',
    this.size = 56,
    this.height,
    this.radius = AppRadius.md,
    super.key,
  });

  final String pirithId;
  final String coverUrl;

  /// Width, and also the height unless [height] overrides it.
  final double size;

  /// Set to show the cover at an aspect ratio other than 1:1 — the player
  /// uses 16:9 so a wide cover isn't cropped down to a square.
  final double? height;
  final double radius;

  double get _height => height ?? size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    if (coverUrl.isEmpty) return _placeholder(borderRadius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        coverUrl,
        width: size,
        height: _height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(borderRadius),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(borderRadius),
      ),
    );
  }

  Widget _placeholder(BorderRadius borderRadius) {
    final color = AppColors.artworkColorForId(pirithId);
    return Container(
      width: size,
      height: _height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
      ),
      child: Center(
        child: PirithMark(
          size: (size < _height ? size : _height) * 0.52,
          color: const Color(0xFFFBF4E6),
        ),
      ),
    );
  }
}
