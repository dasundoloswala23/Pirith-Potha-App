import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../domain/entities/category_entity.dart';

/// Gradient category tile matching the reference `CategoryCard`.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.category,
    required this.index,
    required this.count,
    required this.onTap,
    super.key,
  });

  final CategoryEntity category;
  final int index;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bi = Bilingual.of(context);
    final (lead, sub) = bi.order(category.nameSinhala, category.name);
    final (start, end) = AppColors.categoryGradientFor(index);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        width: 140,
        height: 120,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [start, end],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Both names, ordered by the reader's leading-language choice,
            // matching how Pirith are labelled elsewhere.
            Text(
              lead,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bi.sinhalaFirst
                  ? AppTypography.sinhalaTitle(
                      fontSize: 15,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    )
                  : const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.categoryPirithCount(count),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
