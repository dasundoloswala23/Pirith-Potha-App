import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/pirith_mark.dart';

/// Cover-art placeholder for a Pirith: a colored rounded box with the
/// dhamma-wheel mark centered, rotating through [AppColors.artworkPalette]
/// by [index] — matches the reference `Artwork` component. Swapped for the
/// real `coverUrl` image once cover art exists.
class PirithArtwork extends StatelessWidget {
  const PirithArtwork({
    required this.index,
    this.size = 56,
    this.radius = 12,
    super.key,
  });

  final int index;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.artworkColorFor(index);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
      ),
      child: Center(
        child: PirithMark(size: size * 0.52, color: const Color(0xFFFBF4E6)),
      ),
    );
  }
}
