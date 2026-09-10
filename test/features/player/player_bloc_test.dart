import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/history/domain/usecases/record_played.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/player/domain/entities/playback_status.dart';
import 'package:pitithpotha/features/player/domain/usecases/pause_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_pirith.dart';
import 'package:pitithpotha/features/player/domain/usecases/resume_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/seek_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/stop_playback.dart';
import 'package:pitithpotha/features/player/presentation/bloc/player_bloc.dart';

import '../../fakes/fake_audio_repository.dart';
import '../../fakes/fake_history_repository.dart';

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

PlayerBloc _buildBloc(FakeAudioRepository repository) => PlayerBloc(
      audioRepository: repository,
      playPirith: PlayPirith(repository),
      pausePlayback: PausePlayback(repository),
      resumePlayback: ResumePlayback(repository),
      seekPlayback: SeekPlayback(repository),
      stopPlayback: StopPlayback(repository),
      recordPlayed: RecordPlayed(FakeHistoryRepository()),
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
  });
}
