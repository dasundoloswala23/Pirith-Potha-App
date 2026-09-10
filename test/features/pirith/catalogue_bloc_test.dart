import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/pirith/domain/entities/category_entity.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_active_pirith.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_categories.dart';
import 'package:pitithpotha/features/pirith/presentation/bloc/catalogue_bloc.dart';

import '../../fakes/fake_pirith_repository.dart';

const _category = CategoryEntity(
  id: 'protective',
  name: 'Protective Pirith',
  nameSinhala: 'ආරක්‍ෂක පිරිත්',
  sortOrder: 1,
);

PirithEntity _pirith({
  required String id,
  required String title,
  bool featured = false,
  int playCount = 0,
}) =>
    PirithEntity(
      id: id,
      title: title,
      titleSinhala: title,
      description: '',
      descriptionSinhala: '',
      coverUrl: '',
      audioUrl: '',
      duration: 754,
      categoryId: _category.id,
      isPremium: false,
      isFeatured: featured,
      sortOrder: 1,
      playCount: playCount,
      downloadCount: 0,
    );

void main() {
  group('CatalogueBloc', () {
    test('loads categories and pirith on start', () async {
      final repository = FakePirithRepository(
        categories: const [_category],
        pirith: [
          _pirith(id: '1', title: 'Ratana Sutta', featured: true, playCount: 10),
          _pirith(id: '2', title: 'Mangala Sutta', playCount: 30),
        ],
      );
      final bloc = CatalogueBloc(
        getCategories: GetCategories(repository),
        getActivePirith: GetActivePirith(repository),
      );
      addTearDown(bloc.close);

      final future = expectLater(bloc.stream, emitsThrough(isA<CatalogueLoaded>()));
      bloc.add(const CatalogueStarted());
      await future;

      final state = bloc.state as CatalogueLoaded;
      expect(state.categories, [_category]);
      expect(state.featured.single.id, '1');
      expect(state.popular.first.id, '2'); // higher playCount first
      expect(state.forCategory('protective'), hasLength(2));
      expect(state.search('mangala').single.id, '2');
      expect(state.search(''), isEmpty);
    });

    test('durationLabel formats seconds as m:ss', () {
      expect(_pirith(id: '1', title: 'x').durationLabel(), '12:34');
    });
  });
}
