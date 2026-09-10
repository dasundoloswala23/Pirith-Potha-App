import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/social_links.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/external_link_launcher.dart';

/// Warm, Sinhala-first invitation to follow the official YouTube/Facebook
/// presence — see docs/08_ui_ux.md. A card is hidden if its URL isn't
/// configured yet (see core/constants/social_links.dart).
class SocialSection extends StatelessWidget {
  const SocialSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (SocialLinks.youTubeUrl.isEmpty && SocialLinks.facebookUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.socialHeading,
            style: AppTypography.sinhalaTitle(fontSize: 17, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(l10n.socialSubtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          if (SocialLinks.youTubeUrl.isNotEmpty)
            _SocialCard(
              icon: Icons.play_circle_fill,
              iconColor: const Color(0xFFFF0000),
              title: l10n.socialYouTubeTitle,
              subtitle: l10n.socialYouTubeSubtitle,
              cta: l10n.socialYouTubeCta,
              url: SocialLinks.youTubeUrl,
            ),
          if (SocialLinks.youTubeUrl.isNotEmpty && SocialLinks.facebookUrl.isNotEmpty)
            const SizedBox(height: 10),
          if (SocialLinks.facebookUrl.isNotEmpty)
            _SocialCard(
              icon: Icons.facebook,
              iconColor: const Color(0xFF1877F2),
              title: l10n.socialFacebookTitle,
              subtitle: l10n.socialFacebookSubtitle,
              cta: l10n.socialFacebookCta,
              url: SocialLinks.facebookUrl,
            ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.url,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String cta;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => launchExternalUrl(url),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.sinhalaTitle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      cta,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
