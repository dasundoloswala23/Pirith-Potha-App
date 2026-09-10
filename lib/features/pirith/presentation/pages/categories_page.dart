import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../widgets/catalogue_loaded_builder.dart';
import '../widgets/category_card.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionCategories)),
      body: CatalogueLoadedBuilder(
        builder: (context, state) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 140 / 120,
            ),
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return CategoryCard(
                category: category,
                index: index,
                count: state.forCategory(category.id).length,
                onTap: () => context.push(AppRoutePaths.categoryDetailsFor(category.id)),
              );
            },
          );
        },
      ),
    );
  }
}
