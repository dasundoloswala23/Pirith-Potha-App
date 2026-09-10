import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/favorites_bloc.dart';

/// Heart icon reflecting/toggling real [FavoritesBloc] state — reused by
/// [PirithCard], Pirith details, and the full player (see
/// docs/09_development_roadmap.md, Phase 7).
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({required this.pirithId, this.outlined = false, super.key});

  final String pirithId;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFavorite = context.select<FavoritesBloc, bool>((bloc) {
      final state = bloc.state;
      return state is FavoritesLoaded && state.isFavorite(pirithId);
    });

    final icon = Icon(
      isFavorite ? Icons.favorite : Icons.favorite_outline,
      color: isFavorite ? AppColors.maroon : null,
    );
    void onPressed() => context.read<FavoritesBloc>().add(FavoriteToggled(pirithId));
    final tooltip = l10n.actionAddFavorite;

    return outlined
        ? IconButton.outlined(icon: icon, tooltip: tooltip, onPressed: onPressed)
        : IconButton(icon: icon, tooltip: tooltip, onPressed: onPressed);
  }
}
