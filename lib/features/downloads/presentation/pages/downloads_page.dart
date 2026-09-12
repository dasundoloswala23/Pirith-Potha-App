import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/presentation/bloc/catalogue_bloc.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../bloc/download_bloc.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bi = Bilingual.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DownloadBloc, DownloadState>(
          builder: (context, downloadState) {
            if (downloadState is! DownloadsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final downloadedIds = downloadState.completed
                .map((d) => d.pirithId)
                .toSet();
            if (downloadedIds.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BilingualHeader(
                    sinhala: bi.si.downloadsTitle,
                    english: bi.en.downloadsTitle,
                  ),
                  Expanded(
                    child: EmptyState(
                      sinhalaTitle: bi.si.downloadsEmpty,
                      englishTitle: bi.en.downloadsEmpty,
                    ),
                  ),
                ],
              );
            }

            return BlocBuilder<CatalogueBloc, CatalogueState>(
              builder: (context, catalogueState) {
                if (catalogueState is! CatalogueLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = catalogueState.pirith
                    .where((p) => downloadedIds.contains(p.id))
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BilingualHeader(
                      sinhala: bi.si.downloadsTitle,
                      english: bi.en.downloadsTitle,
                      englishSuffix:
                          '${items.length} pirith · ${bi.en.downloadsOfflineReady}',
                    ),
                    _OfflineBanner(count: items.length),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return PirithCard(item: item);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Reassurance banner from the approved design — states plainly how much of
/// the catalogue will keep working with no connection.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.green),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.downloadsAvailableOffline(count),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
