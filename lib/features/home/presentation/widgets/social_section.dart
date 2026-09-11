import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/social_links.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/services/external_link_launcher.dart';

/// Compact "follow us" row near the top of Home — see docs/08_ui_ux.md.
///
/// Deliberately small: it sits above the catalogue, so a full heading plus
/// body copy plus a large card would push the actual Pirith content off the
/// first screen. Each card is hidden if its URL isn't configured yet (see
/// core/constants/social_links.dart).
///
/// Brand names stay in Latin script in both languages — "YouTube" is a
/// proper noun, and transliterating it reads as a misspelling.
class SocialSection extends StatelessWidget {
  const SocialSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bi = Bilingual.of(context);

    final links = [
      if (SocialLinks.youTubeUrl.isNotEmpty)
        (
          icon: Icons.play_circle_fill,
          color: const Color(0xFFFF0000),
          label: bi.en.socialYouTubeTitle,
          url: SocialLinks.youTubeUrl,
        ),
      if (SocialLinks.facebookUrl.isNotEmpty)
        (
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
          label: bi.en.socialFacebookTitle,
          url: SocialLinks.facebookUrl,
        ),
    ];
    if (links.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final (lead, sub) = bi.order(bi.si.socialHeading, bi.en.socialHeading);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lead,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final link in links) ...[
            const SizedBox(width: AppSpacing.sm),
            _SocialChip(
              icon: link.icon,
              color: link.color,
              label: link.label,
              url: link.url,
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => launchExternalUrl(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
