import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../widgets/catalogue_loaded_builder.dart';
import '../widgets/pirith_card.dart';

/// The whole catalogue in one place, with a search field on top — the
/// "Pirith" bottom-nav destination. Search filters the already-loaded
/// catalogue client-side (see docs/01_product_requirements.md on starting
/// simple rather than reaching for Algolia-grade infrastructure), so an
/// empty query simply shows everything.
class PirithListPage extends StatefulWidget {
  const PirithListPage({super.key});

  @override
  State<PirithListPage> createState() => _PirithListPageState();
}

class _PirithListPageState extends State<PirithListPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bi = Bilingual.of(context);
    final query = _controller.text.trim();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CatalogueLoadedBuilder(
          builder: (context, state) {
            final items = query.isEmpty ? state.pirith : state.search(query);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BilingualHeader(
                  sinhala: bi.si.navPirith,
                  english: bi.en.navPirith,
                  englishSuffix: '${state.pirith.length}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '${bi.si.navSearch} · ${bi.en.searchHint}',
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          sinhalaTitle: bi.si.searchNoResultsTitle,
                          englishTitle: bi.en.searchNoResultsTitle,
                          subtitle: bi.si.searchNoResultsSubtitle,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
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
        ),
      ),
    );
  }
}
