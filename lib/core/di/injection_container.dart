import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_anonymously.dart';
import '../../features/auth/domain/usecases/sign_in_with_apple.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
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

  _registerAuthFeature();

  // Phase 4+ will register catalogue/audio/download repositories and BLoCs
  // here.
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
