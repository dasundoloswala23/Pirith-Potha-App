import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/l10n/app_localizations.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/player/domain/usecases/pause_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_pirith.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_queue.dart';
import 'package:pitithpotha/features/player/domain/usecases/resume_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/seek_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/set_playback_mode.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_next.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_previous.dart';
import 'package:pitithpotha/features/player/domain/usecases/stop_playback.dart';
import 'package:pitithpotha/features/player/presentation/bloc/player_bloc.dart';
import 'package:pitithpotha/features/player/presentation/widgets/video_section.dart';
import 'package:pitithpotha/features/player/presentation/widgets/youtube_preview_card.dart';
import 'package:pitithpotha/features/history/domain/usecases/record_played.dart';

import '../../fakes/fake_audio_repository.dart';
import '../../fakes/fake_history_repository.dart';

// As with youtube_preview_card_test.dart: do NOT assert that the uploaded
// video actually decodes or plays. Flutter's test environment has no real
// platform video decoder, so VideoPlayerController.initialize() always fails
// here — that is an expected, asserted outcome (the graceful-fallback path),
// not a thing to work around. Only widget-type presence/absence is asserted.
PlayerBloc _buildBloc(FakeAudioRepository repository) => PlayerBloc(
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
  recordPlayed: RecordPlayed(FakeHistoryRepository()),
);

const _item = PirithEntity(
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

Future<void> _pump(
  WidgetTester tester,
  PlayerBloc bloc, {
  String videoUrl = '',
  String youtubeUrl = '',
}) {
  return tester.pumpWidget(
    BlocProvider<PlayerBloc>.value(
      value: bloc,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoSection(videoUrl: videoUrl, youtubeUrl: youtubeUrl),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late FakeAudioRepository repository;
  late PlayerBloc bloc;

  setUp(() {
    repository = FakeAudioRepository();
    bloc = _buildBloc(repository);
  });

  tearDown(() => bloc.close());

  testWidgets('neither source renders nothing', (tester) async {
    await _pump(tester, bloc);
    await tester.pump();

    expect(find.byType(AspectRatio), findsNothing);
    expect(find.byType(YouTubePreviewCard), findsNothing);
  });

  testWidgets('YouTube only renders just the YouTube card', (tester) async {
    await _pump(tester, bloc, youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ');
    await tester.pump();

    expect(find.byType(YouTubePreviewCard), findsOneWidget);
    // Only the YouTube card's own AspectRatio — no uploaded-video surface.
    expect(find.byType(AspectRatio), findsOneWidget);
  });

  testWidgets('uploaded video only renders just the video player area', (
    tester,
  ) async {
    await _pump(tester, bloc, videoUrl: 'https://example.com/v.mp4');
    await tester.pump();

    expect(find.byType(YouTubePreviewCard), findsNothing);
    expect(find.byType(AspectRatio), findsOneWidget);
  });

  testWidgets('both sources render uploaded video then YouTube beneath', (
    tester,
  ) async {
    await _pump(
      tester,
      bloc,
      videoUrl: 'https://example.com/v.mp4',
      youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
    );
    await tester.pump();

    expect(find.byType(YouTubePreviewCard), findsOneWidget);
    // One AspectRatio for the uploaded-video surface, one inside the card.
    expect(find.byType(AspectRatio), findsNWidgets(2));

    final videoTop = tester.getTopLeft(find.byType(AspectRatio).first).dy;
    final youtubeTop = tester
        .getTopLeft(find.byType(YouTubePreviewCard))
        .dy;
    expect(videoTop, lessThan(youtubeTop));
  });

  testWidgets(
    'audio starting while an uploaded video is mounted does not throw',
    (tester) async {
      // This is the regression guard for the audio-pauses-video direction
      // (video_section.dart's _onPlayerStateChanged). It cannot assert that
      // the video controller actually pauses: VideoPlayerController never
      // reaches "initialized" in flutter test's environment (no platform
      // video decoder), so the controller stays null and the listener's
      // guard is a no-op. What this does verify is that dispatching a play
      // event while the video section is mounted and still loading/failed
      // is handled safely by the BlocListener with no crash — the actual
      // pause behavior needs a device check (see docs/04_audio_architecture.md).
      await _pump(tester, bloc, videoUrl: 'https://example.com/v.mp4');
      await tester.pump();

      bloc.add(const PlayerPlayRequested(_item));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    },
  );
}
