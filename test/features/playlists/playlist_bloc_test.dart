import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/add_pirith_to_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/create_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/delete_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/remove_pirith_from_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/rename_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/reorder_playlist.dart';
import 'package:pitithpotha/features/playlists/presentation/bloc/playlist_bloc.dart';

import '../../fakes/fake_playlist_repository.dart';

PlaylistBloc _buildBloc(FakePlaylistRepository repository) => PlaylistBloc(
  playlistRepository: repository,
  createPlaylist: CreatePlaylist(repository),
  renamePlaylist: RenamePlaylist(repository),
  deletePlaylist: DeletePlaylist(repository),
  addPirithToPlaylist: AddPirithToPlaylist(repository),
  removePirithFromPlaylist: RemovePirithFromPlaylist(repository),
  reorderPlaylist: ReorderPlaylist(repository),
);

/// Lets the BLoC's event queue and the repository stream drain.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('PlaylistBloc', () {
    test('starts loaded with whatever the repository already holds', () async {
      final repository = FakePlaylistRepository();
      await repository.create(name: 'Existing');

      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);
      await _settle();

      final state = bloc.state;
      expect(state, isA<PlaylistsLoaded>());
      expect((state as PlaylistsLoaded).playlists.single.name, 'Existing');
    });

    test('creating a playlist emits it', () async {
      final repository = FakePlaylistRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const PlaylistCreated(name: 'උදෑසන පිරිත්'));
      await _settle();

      final state = bloc.state as PlaylistsLoaded;
      expect(state.playlists.single.name, 'උදෑසන පිරිත්');
    });

    test('a blank name is ignored rather than creating a nameless playlist',
        () async {
      final repository = FakePlaylistRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const PlaylistCreated(name: '   '));
      await _settle();

      expect((bloc.state as PlaylistsLoaded).playlists, isEmpty);
    });

    test('creating with an initial Pirith adds it in the same step', () async {
      final repository = FakePlaylistRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(
        const PlaylistCreated(name: 'New', initialPirithId: 'pirith-1'),
      );
      await _settle();

      final state = bloc.state as PlaylistsLoaded;
      expect(state.playlists.single.pirithIds, ['pirith-1']);
    });

    test('adding the same Pirith twice leaves one copy', () async {
      final repository = FakePlaylistRepository();
      final playlist = await repository.create(name: 'A');
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc
        ..add(
          PlaylistItemAdded(playlistId: playlist.id, pirithId: 'pirith-1'),
        )
        ..add(
          PlaylistItemAdded(playlistId: playlist.id, pirithId: 'pirith-1'),
        );
      await _settle();

      final state = bloc.state as PlaylistsLoaded;
      expect(state.playlists.single.pirithIds, ['pirith-1']);
      expect(state.contains(playlist.id, 'pirith-1'), isTrue);
    });

    test('removing a Pirith drops it from the playlist', () async {
      final repository = FakePlaylistRepository();
      final playlist = await repository.create(name: 'A');
      await repository.addItem(playlist.id, 'a');
      await repository.addItem(playlist.id, 'b');

      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlaylistItemRemoved(playlistId: playlist.id, pirithId: 'a'));
      await _settle();

      expect((bloc.state as PlaylistsLoaded).playlists.single.pirithIds, ['b']);
    });

    test('reordering emits the new order', () async {
      final repository = FakePlaylistRepository();
      final playlist = await repository.create(name: 'A');
      for (final id in ['a', 'b', 'c']) {
        await repository.addItem(playlist.id, id);
      }

      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(
        PlaylistItemsReordered(
          playlistId: playlist.id,
          oldIndex: 0,
          newIndex: 2,
        ),
      );
      await _settle();

      expect((bloc.state as PlaylistsLoaded).playlists.single.pirithIds, [
        'b',
        'c',
        'a',
      ]);
    });

    test('deleting a playlist removes it from the state', () async {
      final repository = FakePlaylistRepository();
      final playlist = await repository.create(name: 'A');
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlaylistDeleted(playlist.id));
      await _settle();

      final state = bloc.state as PlaylistsLoaded;
      expect(state.playlists, isEmpty);
      expect(state.byId(playlist.id), isNull);
    });

    test('renaming keeps the items', () async {
      final repository = FakePlaylistRepository();
      final playlist = await repository.create(name: 'Old');
      await repository.addItem(playlist.id, 'a');

      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlaylistRenamed(id: playlist.id, name: 'New'));
      await _settle();

      final updated = (bloc.state as PlaylistsLoaded).byId(playlist.id)!;
      expect(updated.name, 'New');
      expect(updated.pirithIds, ['a']);
    });
  });
}
