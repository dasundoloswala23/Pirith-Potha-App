import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/pirith/data/datasources/pirith_local_data_source.dart';
import 'package:pitithpotha/features/pirith/data/datasources/pirith_remote_data_source.dart';
import 'package:pitithpotha/features/pirith/data/models/category_model.dart';
import 'package:pitithpotha/features/pirith/data/models/pirith_model.dart';
import 'package:pitithpotha/features/pirith/data/repositories/pirith_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _category = CategoryModel(id: 'protective', name: 'Protective', nameSinhala: 'x', sortOrder: 1);

const _pirith = PirithModel(
  id: '1',
  title: 'Ratana Sutta',
  titleSinhala: 'රතන සූත්‍රය',
  description: '',
  descriptionSinhala: '',
  coverUrl: '',
  audioUrl: 'https://example.com/audio.mp3',
  duration: 100,
  categoryId: 'protective',
  isPremium: false,
  isFeatured: false,
  sortOrder: 1,
  playCount: 0,
  downloadCount: 0,
);

/// Remote data source fake that can be switched to always-fail, simulating
/// no network — see PirithRepositoryImpl's offline-fallback behavior.
class _FakeRemoteDataSource implements PirithRemoteDataSource {
  bool shouldFail = false;

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (shouldFail) throw Exception('network error');
    return [_category];
  }

  @override
  Future<List<PirithModel>> getActivePirith() async {
    if (shouldFail) throw Exception('network error');
    return [_pirith];
  }

  @override
  Future<PirithModel> getPirithById(String id) async {
    if (shouldFail) throw Exception('network error');
    return _pirith;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back to the local cache when the remote fetch fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localDataSource = PirithLocalDataSource(prefs);
    final remoteDataSource = _FakeRemoteDataSource();
    final repository = PirithRepositoryImpl(remoteDataSource, localDataSource);

    // First call succeeds and populates the cache.
    final categories = await repository.getCategories();
    final pirith = await repository.getActivePirith();
    expect(categories.single.id, 'protective');
    expect(pirith.single.id, '1');

    // Simulate going offline: the remote source now always throws.
    remoteDataSource.shouldFail = true;

    // Cache writes are fire-and-forget in the repository; give them a tick.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final cachedCategories = await repository.getCategories();
    final cachedPirith = await repository.getActivePirith();
    expect(cachedCategories.single.id, 'protective');
    expect(cachedPirith.single.id, '1');

    final cachedById = await repository.getPirithById('1');
    expect(cachedById.id, '1');
  });

  test('surfaces a failure when both remote and cache are empty', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localDataSource = PirithLocalDataSource(prefs);
    final remoteDataSource = _FakeRemoteDataSource()..shouldFail = true;
    final repository = PirithRepositoryImpl(remoteDataSource, localDataSource);

    await expectLater(repository.getCategories(), throwsA(anything));
  });
}
