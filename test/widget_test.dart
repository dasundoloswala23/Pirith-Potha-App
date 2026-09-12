import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pitithpotha/core/l10n/language_cubit.dart';
import 'package:pitithpotha/features/player/presentation/bloc/sleep_timer_cubit.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pitithpotha/app/app.dart';
import 'package:pitithpotha/features/auth/domain/entities/app_user.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_out.dart';
import 'package:pitithpotha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pitithpotha/features/downloads/domain/usecases/cancel_download.dart';
import 'package:pitithpotha/features/downloads/domain/usecases/delete_download.dart';
import 'package:pitithpotha/features/downloads/domain/usecases/download_pirith.dart';
import 'package:pitithpotha/features/downloads/presentation/bloc/download_bloc.dart';
import 'package:pitithpotha/features/favorites/domain/usecases/toggle_favorite.dart';
import 'package:pitithpotha/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:pitithpotha/features/history/domain/usecases/record_played.dart';
import 'package:pitithpotha/features/history/presentation/bloc/history_bloc.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_active_pirith.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_categories.dart';
import 'package:pitithpotha/features/pirith/presentation/bloc/catalogue_bloc.dart';
import 'package:pitithpotha/features/player/domain/usecases/pause_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_pirith.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_queue.dart';
import 'package:pitithpotha/features/player/domain/usecases/set_playback_mode.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_next.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_previous.dart';
import 'package:pitithpotha/features/player/domain/usecases/resume_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/seek_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/stop_playback.dart';
import 'package:pitithpotha/features/player/presentation/bloc/player_bloc.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/add_pirith_to_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/create_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/delete_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/remove_pirith_from_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/rename_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/reorder_playlist.dart';
import 'package:pitithpotha/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:pitithpotha/features/premium/presentation/bloc/premium_bloc.dart';

import 'fakes/fake_audio_repository.dart';
import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_download_repository.dart';
import 'fakes/fake_favorites_repository.dart';
import 'fakes/fake_history_repository.dart';
import 'fakes/fake_pirith_repository.dart';
import 'fakes/fake_playlist_repository.dart';
import 'fakes/fake_premium_repository.dart';

void main() {
  setUpAll(() {
    // Avoid real network calls to Google Fonts in the test sandbox; falls
    // back to the platform's default font, which is fine for these tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App launches on the splash screen, then reaches Home',
      (WidgetTester tester) async {
    final fakeRepository = FakeAuthRepository(
      initialUser: const AppUser(uid: 'guest-1', isAnonymous: true),
    );
    final authBloc = AuthBloc(
      authRepository: fakeRepository,
      signInAnonymously: SignInAnonymously(fakeRepository),
      signInWithGoogle: SignInWithGoogle(fakeRepository),
      signInWithApple: SignInWithApple(fakeRepository),
      signOut: SignOut(fakeRepository),
    )..add(const AuthStarted());
    addTearDown(authBloc.close);

    final fakePirithRepository = FakePirithRepository();
    final catalogueBloc = CatalogueBloc(
      getCategories: GetCategories(fakePirithRepository),
      getActivePirith: GetActivePirith(fakePirithRepository),
    )..add(const CatalogueStarted());
    addTearDown(catalogueBloc.close);

    final fakeHistoryRepository = FakeHistoryRepository();
    final historyBloc = HistoryBloc(historyRepository: fakeHistoryRepository);
    addTearDown(historyBloc.close);

    final fakeAudioRepository = FakeAudioRepository();
    final playerBloc = PlayerBloc(
      audioRepository: fakeAudioRepository,
      playPirith: PlayPirith(fakeAudioRepository),
      playQueue: PlayQueue(fakeAudioRepository),
      skipToNext: SkipToNext(fakeAudioRepository),
      skipToPrevious: SkipToPrevious(fakeAudioRepository),
      setPlaybackMode: SetPlaybackMode(fakeAudioRepository),
      pausePlayback: PausePlayback(fakeAudioRepository),
      resumePlayback: ResumePlayback(fakeAudioRepository),
      seekPlayback: SeekPlayback(fakeAudioRepository),
      stopPlayback: StopPlayback(fakeAudioRepository),
      recordPlayed: RecordPlayed(fakeHistoryRepository),
    );
    addTearDown(playerBloc.close);

    final fakeDownloadRepository = FakeDownloadRepository();
    final downloadBloc = DownloadBloc(
      downloadRepository: fakeDownloadRepository,
      downloadPirith: DownloadPirith(fakeDownloadRepository),
      cancelDownload: CancelDownload(fakeDownloadRepository),
      deleteDownload: DeleteDownload(fakeDownloadRepository),
    );
    addTearDown(downloadBloc.close);

    final fakeFavoritesRepository = FavoritesRepositoryFake();
    final favoritesBloc = FavoritesBloc(
      favoritesRepository: fakeFavoritesRepository,
      toggleFavorite: ToggleFavorite(fakeFavoritesRepository),
    );
    addTearDown(favoritesBloc.close);

    final premiumBloc = PremiumBloc(premiumRepository: FakePremiumRepository());
    addTearDown(premiumBloc.close);

    SharedPreferences.setMockInitialValues({});
    final languageCubit = LanguageCubit(await SharedPreferences.getInstance());
    addTearDown(languageCubit.close);

    final sleepTimerCubit = SleepTimerCubit(playerBloc);
    addTearDown(sleepTimerCubit.close);

    final fakePlaylistRepository = FakePlaylistRepository();
    final playlistBloc = PlaylistBloc(
      playlistRepository: fakePlaylistRepository,
      createPlaylist: CreatePlaylist(fakePlaylistRepository),
      renamePlaylist: RenamePlaylist(fakePlaylistRepository),
      deletePlaylist: DeletePlaylist(fakePlaylistRepository),
      addPirithToPlaylist: AddPirithToPlaylist(fakePlaylistRepository),
      removePirithFromPlaylist: RemovePirithFromPlaylist(
        fakePlaylistRepository,
      ),
      reorderPlaylist: ReorderPlaylist(fakePlaylistRepository),
    );
    addTearDown(playlistBloc.close);

    await tester.pumpWidget(
      PirithPothaApp(
        authBloc: authBloc,
        catalogueBloc: catalogueBloc,
        playerBloc: playerBloc,
        downloadBloc: downloadBloc,
        favoritesBloc: favoritesBloc,
        historyBloc: historyBloc,
        premiumBloc: premiumBloc,
        playlistBloc: playlistBloc,
        languageCubit: languageCubit,
        sleepTimerCubit: sleepTimerCubit,
      ),
    );
    expect(find.byType(PirithPothaApp), findsOneWidget);

    // The splash screen holds for a minimum display time and drives a
    // repeating dots/rotation animation, so settle it with bounded pumps
    // instead of pumpAndSettle (which would time out on the infinite
    // animation). Pump past the full minimum display time so its internal
    // timer fires and the app navigates on to Home before the test ends.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PirithPothaApp), findsOneWidget);
  });
}
