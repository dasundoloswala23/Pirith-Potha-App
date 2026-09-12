import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../bloc/history_bloc.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bi = Bilingual.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionRecentlyPlayed)),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, historyState) {
          if (historyState is! HistoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (historyState.entries.isEmpty) {
            return EmptyState(
              sinhalaTitle: bi.si.recentlyPlayedEmpty,
              englishTitle: bi.en.recentlyPlayedEmpty,
            );
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
                  return PirithCard(item: item);
                },
              );
            },
          );
        },
      ),
    );
  }
}
