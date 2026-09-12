import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/pirith/presentation/bloc/catalogue_bloc.dart';

PirithEntity _make(String id) => PirithEntity(
  id: id,
  title: 'Sutta $id',
  titleSinhala: 'සූත්‍රය $id',
  description: '',
  descriptionSinhala: '',
  coverUrl: '',
  audioUrl: 'https://example.com/$id.mp3',
  duration: 100,
  categoryId: 'protective',
  isPremium: false,
  isFeatured: false,
  sortOrder: 1,
  playCount: 0,
  downloadCount: 0,
);

void main() {
  group('CatalogueLoaded.byIds', () {
    final state = CatalogueLoaded(
      categories: const [],
      pirith: [_make('a'), _make('b'), _make('c')],
    );

    test('resolves ids in the order given, not catalogue order', () {
      expect(
        state.byIds(['c', 'a']).map((item) => item.id),
        ['c', 'a'],
      );
    });

    test('skips ids no longer in the catalogue', () {
      // A Pirith unpublished from the admin app must not blank out or crash
      // a playlist that still lists it.
      expect(
        state.byIds(['a', 'gone', 'b']).map((item) => item.id),
        ['a', 'b'],
      );
    });

    test('an entirely stale list resolves to nothing rather than throwing', () {
      expect(state.byIds(['gone', 'also-gone']), isEmpty);
    });
  });
}
