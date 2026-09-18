import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';

/// Cover art over a soft glow, so the artwork reads as lit rather than
/// pasted onto a flat dark panel.
///
/// Shared by the audio player and the video screen so the two stay visually
/// identical above the fold — the glow and radius are tuned together and
/// would drift immediately if copied.
class PlayerArtwork extends StatelessWidget {
  const PlayerArtwork({
    required this.item,
    required this.width,
    required this.height,
    super.key,
  });

  final PirithEntity item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: PirithArtwork(
        pirithId: item.id,
        coverUrl: item.coverUrl,
        size: width,
        height: height,
        radius: 20,
      ),
    );
  }
}
