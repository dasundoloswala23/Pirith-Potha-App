import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_anonymously.dart';
import '../../features/auth/domain/usecases/sign_in_with_apple.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/downloads/data/repositories/download_repository_impl.dart';
import '../../features/downloads/domain/repositories/download_repository.dart';
import '../../features/downloads/domain/usecases/cancel_download.dart';
import '../../features/downloads/domain/usecases/delete_download.dart';
import '../../features/downloads/domain/usecases/download_pirith.dart';
import '../../features/downloads/presentation/bloc/download_bloc.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/toggle_favorite.dart';
import '../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/record_played.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/pirith/data/datasources/pirith_remote_data_source.dart';
import '../../features/pirith/data/repositories/pirith_repository_impl.dart';
import '../../features/pirith/domain/repositories/pirith_repository.dart';
import '../../features/pirith/domain/usecases/get_active_pirith.dart';
import '../../features/pirith/domain/usecases/get_categories.dart';
import '../../features/pirith/domain/usecases/get_pirith_by_id.dart';
import '../../features/pirith/presentation/bloc/catalogue_bloc.dart';
import '../../features/player/data/repositories/audio_repository_impl.dart';
import '../../features/player/domain/repositories/audio_repository.dart';
import '../../features/player/domain/usecases/pause_playback.dart';
import '../../features/player/domain/usecases/play_pirith.dart';
import '../../features/player/domain/usecases/resume_playback.dart';
import '../../features/player/domain/usecases/seek_playback.dart';
import '../../features/player/domain/usecases/stop_playback.dart';
import '../../features/player/presentation/bloc/player_bloc.dart';
import '../ads/ad_service.dart';
import '../ads/mobile_ads_service.dart';
import '../audio/audio_service_initializer.dart';
import '../audio/pirith_audio_handler.dart';
import '../firebase/analytics_service.dart';

/// App-wide service locator. Repositories/data sources are registered as
/// lazy singletons; screen-scoped BLoCs are registered as factories.
/// [AuthBloc] is app-scoped (one instance for the whole app) since auth
/// state and its guest session need to persist across every screen.
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
    ..registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance)
    ..registerLazySingleton<AnalyticsService>(
      () => AnalyticsService(getIt<FirebaseAnalytics>()),
    );

  final prefs = await SharedPreferences.getInstance();

  _registerAuthFeature();
  _registerPirithFeature();
  await _registerDownloadFeature();
  await _registerFavoritesFeature(prefs);
  await _registerHistoryFeature(prefs);
  await _registerPlayerFeature();
  await _registerAdsFeature();
}

Future<void> _registerAdsFeature() async {
  final service = MobileAdsService();
  await service.initialize();
  getIt.registerSingleton<AdService>(service);
}

Future<void> _registerFavoritesFeature(SharedPreferences prefs) async {
  final repository = FavoritesRepositoryImpl(prefs);
  await repository.initialize();
  getIt
    ..registerSingleton<FavoritesRepository>(repository)
    ..registerLazySingleton(() => ToggleFavorite(getIt<FavoritesRepository>()))
    ..registerLazySingleton(
      () => FavoritesBloc(
        favoritesRepository: getIt<FavoritesRepository>(),
        toggleFavorite: getIt<ToggleFavorite>(),
      ),
    );
}

Future<void> _registerHistoryFeature(SharedPreferences prefs) async {
  final repository = HistoryRepositoryImpl(prefs);
  await repository.initialize();
  getIt
    ..registerSingleton<HistoryRepository>(repository)
    ..registerLazySingleton(() => RecordPlayed(getIt<HistoryRepository>()))
    ..registerLazySingleton(() => HistoryBloc(historyRepository: getIt<HistoryRepository>()));
}

Future<void> _registerDownloadFeature() async {
  final repository = DownloadRepositoryImpl(Dio());
  await repository.initialize();
  getIt
    ..registerSingleton<DownloadRepository>(repository)
    ..registerLazySingleton(() => DownloadPirith(getIt<DownloadRepository>()))
    ..registerLazySingleton(() => CancelDownload(getIt<DownloadRepository>()))
    ..registerLazySingleton(() => DeleteDownload(getIt<DownloadRepository>()))
    ..registerLazySingleton(
      () => DownloadBloc(
        downloadRepository: getIt<DownloadRepository>(),
        downloadPirith: getIt<DownloadPirith>(),
        cancelDownload: getIt<CancelDownload>(),
        deleteDownload: getIt<DeleteDownload>(),
      ),
    );
}

Future<void> _registerPlayerFeature() async {
  final audioHandler = await initializeAudioService();
  getIt
    ..registerSingleton<PirithAudioHandler>(audioHandler)
    ..registerLazySingleton<AudioRepository>(
      () => AudioRepositoryImpl(getIt<PirithAudioHandler>(), getIt<DownloadRepository>()),
    )
    ..registerLazySingleton(() => PlayPirith(getIt<AudioRepository>()))
    ..registerLazySingleton(() => PausePlayback(getIt<AudioRepository>()))
    ..registerLazySingleton(() => ResumePlayback(getIt<AudioRepository>()))
    ..registerLazySingleton(() => SeekPlayback(getIt<AudioRepository>()))
    ..registerLazySingleton(() => StopPlayback(getIt<AudioRepository>()))
    ..registerLazySingleton(
      () => PlayerBloc(
        audioRepository: getIt<AudioRepository>(),
        playPirith: getIt<PlayPirith>(),
        pausePlayback: getIt<PausePlayback>(),
        resumePlayback: getIt<ResumePlayback>(),
        seekPlayback: getIt<SeekPlayback>(),
        stopPlayback: getIt<StopPlayback>(),
        recordPlayed: getIt<RecordPlayed>(),
      ),
    );
}

void _registerPirithFeature() {
  getIt
    ..registerLazySingleton<PirithRemoteDataSource>(
      () => FirestorePirithRemoteDataSource(getIt<FirebaseFirestore>()),
    )
    ..registerLazySingleton<PirithRepository>(
      () => PirithRepositoryImpl(getIt<PirithRemoteDataSource>()),
    )
    ..registerLazySingleton(() => GetCategories(getIt<PirithRepository>()))
    ..registerLazySingleton(() => GetActivePirith(getIt<PirithRepository>()))
    ..registerLazySingleton(() => GetPirithById(getIt<PirithRepository>()))
    ..registerLazySingleton(
      () => CatalogueBloc(
        getCategories: getIt<GetCategories>(),
        getActivePirith: getIt<GetActivePirith>(),
      )..add(const CatalogueStarted()),
    );
}

void _registerAuthFeature() {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => FirebaseAuthRemoteDataSource(getIt<FirebaseAuth>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()),
    )
    ..registerLazySingleton(() => SignInAnonymously(getIt<AuthRepository>()))
    ..registerLazySingleton(() => SignInWithGoogle(getIt<AuthRepository>()))
    ..registerLazySingleton(() => SignInWithApple(getIt<AuthRepository>()))
    ..registerLazySingleton(() => SignOut(getIt<AuthRepository>()))
    ..registerLazySingleton(
      () => AuthBloc(
        authRepository: getIt<AuthRepository>(),
        signInAnonymously: getIt<SignInAnonymously>(),
        signInWithGoogle: getIt<SignInWithGoogle>(),
        signInWithApple: getIt<SignInWithApple>(),
        signOut: getIt<SignOut>(),
      )..add(const AuthStarted()),
    );
}
