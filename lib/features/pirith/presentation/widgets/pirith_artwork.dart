import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/pirith_mark.dart';

/// Cover-art placeholder for a Pirith: a colored rounded box with the
/// dhamma-wheel mark centered, its color derived from [pirithId] via
/// [AppColors.artworkColorForId]. Keying on the id (rather than the item's
/// position in whichever list is rendering it) keeps one Pirith the same
/// color everywhere it appears. Swapped for the real `coverUrl` image once
/// cover art exists.
class PirithArtwork extends StatelessWidget {
  const PirithArtwork({
    required this.pirithId,
    this.size = 56,
    this.radius = AppRadius.md,
    super.key,
  });

  final String pirithId;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.artworkColorForId(pirithId);
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
