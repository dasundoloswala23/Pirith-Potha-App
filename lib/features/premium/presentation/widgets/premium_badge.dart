import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Small "ප්‍රිමියම්" tag shown on premium-only Pirith — see
/// docs/07_monetization.md.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold),
      ),
      child: Text(
        l10n.profilePremium,
        style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w600),
      ),
    );
  }
}
