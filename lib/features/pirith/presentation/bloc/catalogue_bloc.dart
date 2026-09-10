import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/pirith_entity.dart';
import '../../domain/usecases/get_active_pirith.dart';
import '../../domain/usecases/get_categories.dart';

part 'catalogue_event.dart';
part 'catalogue_state.dart';

/// App-scoped BLoC (one instance for the whole app) loading the active
/// catalogue once and serving Home, Search, Categories, and category
/// listing screens from the same in-memory lists — see
/// docs/02_architecture.md and the `PirithRepository.getActivePirith` doc
/// comment for why a full fetch is the right tradeoff at this scale.
class CatalogueBloc extends Bloc<CatalogueEvent, CatalogueState> {
  CatalogueBloc({
    required GetCategories getCategories,
    required GetActivePirith getActivePirith,
  }) : _getCategories = getCategories,
       _getActivePirith = getActivePirith,
       super(const CatalogueInitial()) {
    on<CatalogueStarted>(_onLoad);
    on<CatalogueRefreshRequested>(_onLoad);
  }

  final GetCategories _getCategories;
  final GetActivePirith _getActivePirith;

  Future<void> _onLoad(
    CatalogueEvent event,
    Emitter<CatalogueState> emit,
  ) async {
    // A pull-to-refresh over already-loaded content keeps that content on
    // screen instead of replacing it with a full-screen spinner. Retrying
    // from the error view still shows one, since the state isn't Loaded.
    if (!(event is CatalogueRefreshRequested && state is CatalogueLoaded)) {
      emit(const CatalogueLoading());
    }
    try {
      final categories = await _getCategories();
      final pirith = await _getActivePirith();
      emit(
        CatalogueLoaded(
          categories: categories,
          pirith: pirith,
          fetchedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      final failure = e is AppException ? e.failure : const UnknownFailure();
      emit(CatalogueError(failure));
    }
  }
}
