part of 'catalogue_bloc.dart';

sealed class CatalogueEvent extends Equatable {
  const CatalogueEvent();

  @override
  List<Object?> get props => [];
}

class CatalogueStarted extends CatalogueEvent {
  const CatalogueStarted();
}

class CatalogueRefreshRequested extends CatalogueEvent {
  const CatalogueRefreshRequested();
}
