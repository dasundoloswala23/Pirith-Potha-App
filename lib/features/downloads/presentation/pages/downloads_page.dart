import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/presentation/bloc/catalogue_bloc.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../bloc/download_bloc.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: BlocBuilder<DownloadBloc, DownloadState>(
        builder: (context, downloadState) {
          if (downloadState is! DownloadsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final downloadedIds = downloadState.completed
              .map((d) => d.pirithId)
              .toSet();
          if (downloadedIds.isEmpty) {
            return _EmptyDownloads(l10n: l10n);
          }

          return BlocBuilder<CatalogueBloc, CatalogueState>(
            builder: (context, catalogueState) {
              if (catalogueState is! CatalogueLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = catalogueState.pirith
                  .where((p) => downloadedIds.contains(p.id))
                  .toList();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return PirithCard(
                    item: item,
                    onTap: () =>
                        context.push(AppRoutePaths.pirithDetailsFor(item.id)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PirithMark(
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(l10n.downloadsEmpty),
        ],
      ),
    );
  }
}
