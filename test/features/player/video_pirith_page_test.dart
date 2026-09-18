import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/l10n/app_localizations.dart';
import 'package:pitithpotha/core/l10n/language_cubit.dart';
import 'package:pitithpotha/features/favorites/domain/usecases/toggle_favorite.dart';
import 'package:pitithpotha/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_active_pirith.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_categories.dart';
import 'package:pitithpotha/features/pirith/presentation/bloc/catalogue_bloc.dart';
import 'package:pitithpotha/features/player/domain/usecases/pause_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_pirith.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_queue.dart';
import 'package:pitithpotha/features/player/domain/usecases/resume_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/seek_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/set_playback_mode.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_next.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_previous.dart';
import 'package:pitithpotha/features/player/domain/usecases/stop_playback.dart';
import 'package:pitithpotha/features/history/domain/usecases/record_played.dart';
import 'package:pitithpotha/features/player/presentation/bloc/player_bloc.dart';
import 'package:pitithpotha/features/player/presentation/pages/video_pirith_page.dart';
import 'package:pitithpotha/features/player/presentation/widgets/youtube_preview_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_audio_repository.dart';
import '../../fakes/fake_favorites_repository.dart';
import '../../fakes/fake_history_repository.dart';
import '../../fakes/fake_pirith_repository.dart';

PirithEntity _video(String id) => PirithEntity(
  id: id,
  title: 'Maha Piritha',
  titleSinhala: 'මහ පිරිත',
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

void main() {
  Future<void> pump(WidgetTester tester, List<PirithEntity> catalogue) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final pirithRepository = FakePirithRepository(pirith: catalogue);
    final catalogueBloc = CatalogueBloc(
      getCategories: GetCategories(pirithRepository),
      getActivePirith: GetActivePirith(pirithRepository),
    )..add(const CatalogueStarted());
    addTearDown(catalogueBloc.close);

    final favoritesRepository = FavoritesRepositoryFake();
    final favoritesBloc = FavoritesBloc(
      favoritesRepository: favoritesRepository,
      toggleFavorite: ToggleFavorite(favoritesRepository),
    );
    addTearDown(favoritesBloc.close);

    // The page docks a MiniPlayerBar, which needs a PlayerBloc even when
    // nothing is playing.
    final audioRepository = FakeAudioRepository();
    final playerBloc = PlayerBloc(
      audioRepository: audioRepository,
      playPirith: PlayPirith(audioRepository),
      playQueue: PlayQueue(audioRepository),
      skipToNext: SkipToNext(audioRepository),
      skipToPrevious: SkipToPrevious(audioRepository),
      setPlaybackMode: SetPlaybackMode(audioRepository),
      pausePlayback: PausePlayback(audioRepository),
      resumePlayback: ResumePlayback(audioRepository),
      seekPlayback: SeekPlayback(audioRepository),
      stopPlayback: StopPlayback(audioRepository),
      recordPlayed: RecordPlayed(FakeHistoryRepository()),
    );
    addTearDown(playerBloc.close);

    final languageCubit = LanguageCubit(prefs);
    addTearDown(languageCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: catalogueBloc),
          BlocProvider.value(value: favoritesBloc),
          BlocProvider.value(value: playerBloc),
          BlocProvider.value(value: languageCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: VideoPirithPage(pirithId: 'v1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the video card and none of the audio controls', (
    tester,
  ) async {
    await pump(tester, [_video('v1')]);

    expect(find.byType(YouTubePreviewCard), findsOneWidget);
    expect(find.text('This Pirith is video only'), findsOneWidget);

    // The whole point: nothing that acts on audio.
    expect(find.byType(Slider), findsNothing);
    expect(find.byIcon(Icons.bedtime_outlined), findsNothing);
    expect(find.byIcon(Icons.download_outlined), findsNothing);
    expect(find.text('0:00'), findsNothing);
  });

  testWidgets('refuses to render for a Pirith that has audio', (tester) async {
    // A deep link must never produce a player-shaped screen with no
    // controls for something that is perfectly playable.
    final withAudio = PirithEntity(
      id: 'v1',
      title: 'Ratana Sutta',
      titleSinhala: 'රතන සූත්‍රය',
      description: '',
      descriptionSinhala: '',
      coverUrl: '',
      audioUrl: 'https://example.com/a.mp3',
      youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
      duration: 100,
      categoryId: 'protective',
      isPremium: false,
      isFeatured: false,
      sortOrder: 1,
      playCount: 0,
      downloadCount: 0,
    );

    await pump(tester, [withAudio]);
    expect(find.byType(YouTubePreviewCard), findsNothing);
  });

  testWidgets('falls back when the id is unknown', (tester) async {
    await pump(tester, const []);
    expect(find.byType(YouTubePreviewCard), findsNothing);
  });
}
