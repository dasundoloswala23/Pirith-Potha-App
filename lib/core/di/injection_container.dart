import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import '../firebase/analytics_service.dart';

/// App-wide service locator. Repositories/data sources are registered as
/// lazy singletons; screen-scoped BLoCs are registered as factories.
/// Feature phases add their own `registerXFeature(getIt)` calls here as
/// they're implemented.
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

  // Phase 3+ will register feature repositories, data sources, and BLoCs
  // here (e.g. AuthRepository, PirithRepository).
}
