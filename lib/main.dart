import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injection_container.dart';
import 'core/firebase/firebase_initializer.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/downloads/presentation/bloc/download_bloc.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/pirith/presentation/bloc/catalogue_bloc.dart';
import 'features/player/presentation/bloc/player_bloc.dart';
import 'features/premium/presentation/bloc/premium_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await configureDependencies();
  runApp(
    PirithPothaApp(
      authBloc: getIt<AuthBloc>(),
      catalogueBloc: getIt<CatalogueBloc>(),
      playerBloc: getIt<PlayerBloc>(),
      downloadBloc: getIt<DownloadBloc>(),
      favoritesBloc: getIt<FavoritesBloc>(),
      historyBloc: getIt<HistoryBloc>(),
      premiumBloc: getIt<PremiumBloc>(),
    ),
  );
}
