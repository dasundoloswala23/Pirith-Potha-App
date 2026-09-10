import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/pirith_mark.dart';
import '../../../pirith/presentation/bloc/catalogue_bloc.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';

/// Client-side substring search over the catalogue already loaded by
/// [CatalogueBloc] — see docs/01_product_requirements.md on starting with
/// simple Firestore/local search rather than Algolia-grade infrastructure.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.searchHint,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: BlocBuilder<CatalogueBloc, CatalogueState>(
        builder: (context, state) {
          if (state is! CatalogueLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.text.trim().isEmpty) {
            return _EmptyHint(l10n: l10n);
          }

          final results = state.search(_controller.text);
          if (results.isEmpty) {
            return _NoResults(l10n: l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = results[index];
              return PirithCard(
                item: item,
                artworkIndex: index,
                onTap: () => context.push(AppRoutePaths.pirithDetailsFor(item.id)),
              );
            },
          );
        },
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PirithMark(
            size: 56,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(l10n.searchNoResultsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.searchNoResultsSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PirithMark(
            size: 56,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(l10n.searchHint),
        ],
      ),
    );
  }
}
