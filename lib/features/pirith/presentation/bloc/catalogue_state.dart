part of 'catalogue_bloc.dart';

sealed class CatalogueState extends Equatable {
  const CatalogueState();

  @override
  List<Object?> get props => [];
}

class CatalogueInitial extends CatalogueState {
  const CatalogueInitial();
}

class CatalogueLoading extends CatalogueState {
  const CatalogueLoading();
}

class CatalogueLoaded extends CatalogueState {
  const CatalogueLoaded({
    required this.categories,
    required this.pirith,
    this.fetchedAt,
  });

  final List<CategoryEntity> categories;
  final List<PirithEntity> pirith;

  /// Part of [props] so that a refresh returning byte-identical data still
  /// emits a distinct state — otherwise Equatable suppresses the emit and
  /// anything awaiting the next state (the pull-to-refresh indicator on
  /// Home) would wait forever.
  final DateTime? fetchedAt;

  List<PirithEntity> get featured => pirith.where((p) => p.isFeatured).toList();

  /// No real play-count data yet in most catalogues, so this falls back to
  /// catalogue order — see docs/03_database_schema.md on `playCount`.
  List<PirithEntity> get popular {
    final sorted = [...pirith]
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return sorted;
  }

  /// Resolves stored ids (playlists, favorites) to catalogue entries, in the
  /// order given. Ids with no match are **skipped**: a Pirith unpublished in
  /// the admin app must not crash or blank out a playlist that still lists
  /// it.
  List<PirithEntity> byIds(List<String> ids) {
    final index = {for (final item in pirith) item.id: item};
    return [for (final id in ids) ?index[id]];
  }

  List<PirithEntity> forCategory(String categoryId) =>
      pirith.where((p) => p.categoryId == categoryId).toList();

  List<PirithEntity> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    return pirith
        .where(
          (p) =>
              p.title.toLowerCase().contains(normalized) ||
              p.titleSinhala.toLowerCase().contains(normalized),
        )
        .toList();
  }

  @override
  List<Object?> get props => [categories, pirith, fetchedAt];
}

class CatalogueError extends CatalogueState {
  const CatalogueError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
