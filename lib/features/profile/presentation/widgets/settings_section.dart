import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

/// Uppercase group heading above a run of settings rows ("APPEARANCE",
/// "PLAYBACK", "STORAGE") — the grouping from the approved design, which
/// replaces the previous flat list of tiles.
class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// A settings row with the English label leading and the Sinhala beneath —
/// the reverse of the screen headers, matching the approved design.
///
/// [enabled] renders a row that is visibly not yet active rather than one
/// that silently does nothing when tapped.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.english,
    required this.sinhala,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String english;
  final String sinhala;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final opacity = enabled ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: ListTile(
        enabled: enabled && onTap != null,
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          english,
          style: theme.textTheme.bodyLarge?.copyWith(color: color),
        ),
        subtitle: Text(
          sinhala,
          style: AppTypography.sinhalaBody(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
