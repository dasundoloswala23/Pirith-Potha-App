import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../bloc/catalogue_bloc.dart';

/// Every screen that reads the catalogue needs the same three states
/// (loading/error/loaded); before Phase 10 most of them only handled
/// loading+loaded and would spin forever on a real Firestore/network
/// error. Centralizing it here means fixing that gap once instead of in
/// eight separate screens, and any future screen gets the retry-on-error
/// behavior for free.
class CatalogueLoadedBuilder extends StatelessWidget {
  const CatalogueLoadedBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, CatalogueLoaded state) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogueBloc, CatalogueState>(
      builder: (context, state) {
        return switch (state) {
          CatalogueLoaded() => builder(context, state),
          CatalogueError() => CatalogueErrorView(
              onRetry: () =>
                  context.read<CatalogueBloc>().add(const CatalogueRefreshRequested()),
            ),
          CatalogueLoading() || CatalogueInitial() =>
            const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }
}

class CatalogueErrorView extends StatelessWidget {
  const CatalogueErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.authErrorGeneric),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
        ],
      ),
    );
  }
}
