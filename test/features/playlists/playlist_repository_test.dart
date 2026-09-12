import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PlaylistRepositoryImpl> _buildRepository([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final repository = PlaylistRepositoryImpl(
    await SharedPreferences.getInstance(),
  );
  await repository.initialize();
  return repository;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaylistRepositoryImpl', () {
    test('gives every playlist a distinct id', () async {
      final repository = await _buildRepository();

      final first = await repository.create(name: 'උදෑසන');
      final second = await repository.create(name: 'උදෑසන');

      expect(first.id, isNot(second.id));
      expect(repository.currentPlaylists, hasLength(2));
    });

    test('survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final first = PlaylistRepositoryImpl(prefs);
      await first.initialize();
      final created = await first.create(name: 'සවස', description: 'පිරිත්');
      await first.addItem(created.id, 'pirith-1');

      // A second instance over the same store is what a relaunch looks like.
      final second = PlaylistRepositoryImpl(prefs);
      await second.initialize();

      final restored = second.playlistById(created.id);
      expect(restored, isNotNull);
      expect(restored!.name, 'සවස');
      expect(restored.description, 'පිරිත්');
      expect(restored.pirithIds, ['pirith-1']);
    });

    test('drops malformed entries instead of losing the whole store', () async {
      final good = {
        'id': 'pl_1',
        'name': 'Good',
        'description': '',
        'coverImagePath': null,
        'pirithIds': ['a'],
        'createdAt': 1,
        'updatedAt': 2,
      };
      final repository = await _buildRepository({
        'playlists_v1': <String>[
          jsonEncode(good),
          'not json at all',
          jsonEncode({'name': 'no id'}),
        ],
      });

      expect(repository.currentPlaylists, hasLength(1));
      expect(repository.currentPlaylists.single.id, 'pl_1');
    });

    test('adding the same Pirith twice is a no-op', () async {
      final repository = await _buildRepository();
      final playlist = await repository.create(name: 'A');

      expect(await repository.addItem(playlist.id, 'pirith-1'), isTrue);
      expect(await repository.addItem(playlist.id, 'pirith-1'), isFalse);

      expect(repository.playlistById(playlist.id)!.pirithIds, ['pirith-1']);
    });

    test('removing an item leaves the rest in order', () async {
      final repository = await _buildRepository();
      final playlist = await repository.create(name: 'A');
      for (final id in ['a', 'b', 'c']) {
        await repository.addItem(playlist.id, id);
      }

      await repository.removeItem(playlist.id, 'b');

      expect(repository.playlistById(playlist.id)!.pirithIds, ['a', 'c']);
    });

    test('reorder moves an item to the given final index', () async {
      final repository = await _buildRepository();
      final playlist = await repository.create(name: 'A');
      for (final id in ['a', 'b', 'c', 'd']) {
        await repository.addItem(playlist.id, id);
      }

      // Downwards: 'a' ends up third. onReorderItem already reports the
      // final index, so the repository must not shift it again.
      await repository.reorder(playlist.id, 0, 2);
      expect(repository.playlistById(playlist.id)!.pirithIds, [
        'b',
        'c',
        'a',
        'd',
      ]);

      // Upwards.
      await repository.reorder(playlist.id, 3, 0);
      expect(repository.playlistById(playlist.id)!.pirithIds, [
        'd',
        'b',
        'c',
        'a',
      ]);
    });

    test('reorder ignores out-of-range indices', () async {
      final repository = await _buildRepository();
      final playlist = await repository.create(name: 'A');
      await repository.addItem(playlist.id, 'a');

      await repository.reorder(playlist.id, 5, 0);

      expect(repository.playlistById(playlist.id)!.pirithIds, ['a']);
    });

    test('deleting removes only the named playlist', () async {
      final repository = await _buildRepository();
      final keep = await repository.create(name: 'Keep');
      final drop = await repository.create(name: 'Drop');

      await repository.delete(drop.id);

      expect(repository.playlistById(drop.id), isNull);
      expect(repository.playlistById(keep.id), isNotNull);
    });

    test('the newest-updated playlist sorts first', () async {
      final repository = await _buildRepository();
      final first = await repository.create(name: 'First');
      await repository.create(name: 'Second');

      // Touching the older playlist should float it back to the top.
      await repository.addItem(first.id, 'pirith-1');

      expect(repository.currentPlaylists.first.id, first.id);
    });
  });
}
