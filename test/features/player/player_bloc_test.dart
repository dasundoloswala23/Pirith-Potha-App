import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/history/domain/usecases/record_played.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/player/domain/entities/playback_status.dart';
import 'package:pitithpotha/features/player/domain/usecases/pause_playback.dart';
import 'package:pitithpotha/features/player/domain/entities/playback_mode.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_pirith.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_queue.dart';
import 'package:pitithpotha/features/player/domain/usecases/set_playback_mode.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_next.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_previous.dart';
import 'package:pitithpotha/features/player/domain/usecases/resume_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/seek_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/stop_playback.dart';
import 'package:pitithpotha/features/player/presentation/bloc/player_bloc.dart';

import '../../fakes/fake_audio_repository.dart';
import '../../fakes/fake_history_repository.dart';

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

PirithEntity _videoOnly(String id) => PirithEntity(
  id: id,
  title: 'Video $id',
  titleSinhala: 'වීඩියෝ $id',
  description: '',
  descriptionSinhala: '',
  coverUrl: '',
  audioUrl: '',
  youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
  duration: 0,
  categoryId: 'protective',
  isPremium: false,
  isFeatured: false,
  sortOrder: 1,
  playCount: 0,
  downloadCount: 0,
);

const _item = PirithEntity(
  id: '1',
  title: 'Ratana Sutta',
  titleSinhala: 'රතන සූත්‍රය',
  description: '',
  descriptionSinhala: '',
  coverUrl: '',
  audioUrl: 'https://example.com/audio.mp3',
  duration: 1102,
  categoryId: 'protective',
  isPremium: false,
  isFeatured: false,
  sortOrder: 1,
  playCount: 0,
  downloadCount: 0,
);

PlayerBloc _buildBloc(
  FakeAudioRepository repository, {
  FakeHistoryRepository? history,
}) => PlayerBloc(
      audioRepository: repository,
      playPirith: PlayPirith(repository),
      playQueue: PlayQueue(repository),
      skipToNext: SkipToNext(repository),
      skipToPrevious: SkipToPrevious(repository),
      setPlaybackMode: SetPlaybackMode(repository),
      pausePlayback: PausePlayback(repository),
      resumePlayback: ResumePlayback(repository),
      seekPlayback: SeekPlayback(repository),
      stopPlayback: StopPlayback(repository),
      recordPlayed: RecordPlayed(history ?? FakeHistoryRepository()),
    );

void main() {
  group('PlayerBloc', () {
    test('play transitions Idle -> loading -> playing', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<PlayerActive>().having((s) => s.status, 'status', PlaybackStatus.loading),
          isA<PlayerActive>().having((s) => s.status, 'status', PlaybackStatus.playing),
        ]),
      );

      bloc.add(const PlayerPlayRequested(_item));
      await future;
    });

    test('pause/resume toggle status', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const PlayerPlayRequested(_item));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emits(isA<PlayerActive>().having((s) => s.status, 'status', PlaybackStatus.paused)),
      );
      bloc.add(const PlayerPauseRequested());
      await future;
    });

    test('stop returns to Idle', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const PlayerPlayRequested(_item));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(bloc.stream, emits(isA<PlayerIdle>()));
      bloc.add(const PlayerStopRequested());
      await future;
    });

    test('playing a queue starts at the requested index', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      final items = [_make('a'), _make('b'), _make('c')];
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          isA<PlayerActive>()
              .having((s) => s.item.id, 'item', 'b')
              .having((s) => s.queue.length, 'queue length', 3)
              .having((s) => s.queueIndex, 'index', 1),
        ),
      );

      bloc.add(PlayerQueueRequested(items, startIndex: 1));
      await future;
    });

    test('next advances through the queue', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlayerQueueRequested([_make('a'), _make('b'), _make('c')]));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emitsThrough(isA<PlayerActive>().having((s) => s.item.id, 'item', 'b')),
      );
      bloc.add(const PlayerNextRequested());
      await future;
    });

    test('previous wraps to the end of the queue', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlayerQueueRequested([_make('a'), _make('b'), _make('c')]));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emitsThrough(isA<PlayerActive>().having((s) => s.item.id, 'item', 'c')),
      );
      bloc.add(const PlayerPreviousRequested());
      await future;
    });

    test('a finished track auto-advances to the next one', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlayerQueueRequested([_make('a'), _make('b')]));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emitsThrough(isA<PlayerActive>().having((s) => s.item.id, 'item', 'b')),
      );
      repository.completeCurrent();
      await future;
    });

    test('repeat one stays on the same item when it finishes', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(
        PlayerQueueRequested([
          _make('a'),
          _make('b'),
        ], mode: PlaybackMode.repeatOne),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repository.completeCurrent();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect((bloc.state as PlayerActive).item.id, 'a');
    });

    test('repeat all wraps from the last item back to the first', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(
        PlayerQueueRequested([
          _make('a'),
          _make('b'),
        ], startIndex: 1, mode: PlaybackMode.repeatAll),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emitsThrough(isA<PlayerActive>().having((s) => s.item.id, 'item', 'a')),
      );
      repository.completeCurrent();
      await future;
    });

    test('normal mode stops rather than wrapping at the end', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlayerQueueRequested([_make('a'), _make('b')], startIndex: 1));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repository.completeCurrent();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = bloc.state as PlayerActive;
      expect(state.item.id, 'b');
      expect(state.hasNext, isFalse);
    });

    test('changing mode is reflected in state and repository', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlayerQueueRequested([_make('a'), _make('b')]));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      bloc.add(const PlayerModeChanged(PlaybackMode.shuffle));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect((bloc.state as PlayerActive).mode, PlaybackMode.shuffle);
      expect(repository.mode, PlaybackMode.shuffle);
    });

    test('selecting a queue item jumps straight to it', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(PlayerQueueRequested([_make('a'), _make('b'), _make('c')]));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emitsThrough(isA<PlayerActive>().having((s) => s.item.id, 'item', 'c')),
      );
      bloc.add(const PlayerQueueIndexSelected(2));
      await future;
    });

    test('a single Pirith is a queue of one with no skips offered', () async {
      final repository = FakeAudioRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const PlayerPlayRequested(_item));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = bloc.state as PlayerActive;
      expect(state.queue, hasLength(1));
      expect(state.hasNext, isFalse);
      expect(state.hasPrevious, isFalse);
    });

    group('items with no audio', () {
      test('are refused rather than left loading forever', () async {
        final repository = FakeAudioRepository();
        final history = FakeHistoryRepository();
        final bloc = _buildBloc(repository, history: history);
        addTearDown(bloc.close);

        bloc.add(PlayerPlayRequested(_videoOnly('v')));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // No PlayerActive at all — the old behaviour emitted `loading` and
        // then never moved off it, leaving a permanent spinner.
        expect(bloc.state, isA<PlayerIdle>());
        expect(repository.queue, isEmpty);
        // And it never counted as played.
        expect(history.currentHistory, isEmpty);
      });

      test('do not interrupt what is already playing', () async {
        // The behaviour the video-only screen depends on: opening a video
        // must leave the current chant alone. Previously the UI switched to
        // the new item while the old audio kept going underneath it.
        final repository = FakeAudioRepository();
        final bloc = _buildBloc(repository);
        addTearDown(bloc.close);

        bloc.add(const PlayerPlayRequested(_item));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        bloc.add(PlayerPlayRequested(_videoOnly('v')));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = bloc.state as PlayerActive;
        expect(state.item.id, '1');
        expect(state.status, PlaybackStatus.playing);
      });

      test('are filtered out of a queue without shifting the others', () async {
        final repository = FakeAudioRepository();
        final bloc = _buildBloc(repository);
        addTearDown(bloc.close);

        bloc.add(
          PlayerQueueRequested([
            _make('a'),
            _videoOnly('v'),
            _make('b'),
          ], startIndex: 2),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = bloc.state as PlayerActive;
        expect(state.queue.map((i) => i.id), ['a', 'b']);
        expect(state.queueIndex, 1);
        expect(state.item.id, 'b');
        expect(repository.queue.map((i) => i.id), ['a', 'b']);
      });

      test('skipping by index lands on the right track', () async {
        // The desync regression: with the video still in state.queue,
        // index 1 resolved to the video rather than to 'b'.
        final repository = FakeAudioRepository();
        final bloc = _buildBloc(repository);
        addTearDown(bloc.close);

        bloc.add(
          PlayerQueueRequested([_make('a'), _videoOnly('v'), _make('b')]),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final future = expectLater(
          bloc.stream,
          emitsThrough(isA<PlayerActive>().having((s) => s.item.id, 'item', 'b')),
        );
        bloc.add(const PlayerQueueIndexSelected(1));
        await future;
      });

      test('a queue of nothing but videos plays nothing', () async {
        final repository = FakeAudioRepository();
        final bloc = _buildBloc(repository);
        addTearDown(bloc.close);

        bloc.add(PlayerQueueRequested([_videoOnly('v'), _videoOnly('w')]));
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(bloc.state, isA<PlayerIdle>());
        expect(repository.queue, isEmpty);
      });
    });
  });
}
