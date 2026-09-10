import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injection_container.dart';
import 'core/firebase/firebase_initializer.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await configureDependencies();
  runApp(PirithPothaApp(authBloc: getIt<AuthBloc>()));
}
