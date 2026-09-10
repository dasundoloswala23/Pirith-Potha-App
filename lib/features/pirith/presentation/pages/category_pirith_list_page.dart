import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/catalogue_bloc.dart';
import '../widgets/pirith_card.dart';

class CategoryPirithListPage extends StatelessWidget {
  const CategoryPirithListPage({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<CatalogueBloc, CatalogueState>(
        builder: (context, state) {
          if (state is! CatalogueLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final category = state.categories.where((c) => c.id == categoryId).firstOrNull;
          final items = state.forCategory(categoryId);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(category?.nameSinhala ?? categoryId),
                pinned: true,
              ),
              if (items.isEmpty)
                SliverFillRemaining(child: Center(child: Text(l10n.comingSoon)))
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return PirithCard(
                        item: item,
                        artworkIndex: index,
                        onTap: () =>
                            context.push(AppRoutePaths.pirithDetailsFor(item.id)),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
