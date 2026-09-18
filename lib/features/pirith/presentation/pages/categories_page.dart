import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../widgets/catalogue_loaded_builder.dart';
import '../widgets/category_card.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bi = Bilingual.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(anchored: true),
      body: SafeArea(
        bottom: false,
        child: CatalogueLoadedBuilder(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BilingualHeader(
                sinhala: bi.si.sectionCategories,
                english: bi.en.sectionCategories,
                englishSuffix: '${state.categories.length}',
              ),
              Expanded(
                child: GridView.builder(
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
