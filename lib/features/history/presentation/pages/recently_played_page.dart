import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../bloc/history_bloc.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionRecentlyPlayed)),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, historyState) {
          if (historyState is! HistoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (historyState.entries.isEmpty) {
            return _EmptyHistory(l10n: l10n);
          }

          return CatalogueLoadedBuilder(
            builder: (context, catalogueState) {
              final byId = {for (final p in catalogueState.pirith) p.id: p};
              final items = [
                for (final entry in historyState.entries)
                  if (byId[entry.pirithId] != null) byId[entry.pirithId]!,
              ];

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return PirithCard(
                    item: item,
                    artworkIndex: index,
                    onTap: () => context.push(AppRoutePaths.pirithDetailsFor(item.id)),
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PirithMark(
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(l10n.recentlyPlayedEmpty),
        ],
      ),
    );
  }
}
