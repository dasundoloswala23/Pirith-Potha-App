import 'package:get_it/get_it.dart';

/// App-wide service locator. Repositories/data sources are registered as
/// lazy singletons; screen-scoped BLoCs are registered as factories.
/// Feature phases add their own `registerXFeature(getIt)` calls here as
/// they're implemented — nothing to register yet in the foundation phase.
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Phase 2+ will register Firebase-backed repositories, data sources, and
  // feature BLoCs here.
}
