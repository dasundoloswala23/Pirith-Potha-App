import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_localizations.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/downloads/presentation/bloc/download_bloc.dart';
import '../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../features/history/presentation/bloc/history_bloc.dart';
import '../features/pirith/presentation/bloc/catalogue_bloc.dart';
import '../features/player/presentation/bloc/player_bloc.dart';
import '../features/premium/presentation/bloc/premium_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// BLoCs are injected rather than pulled from the global service locator
/// here, so widget tests can supply fake-repository-backed instances
/// instead of needing a live Firebase/audio connection.
///
/// V1 is Sinhala-first with no in-app language switcher (see
/// docs/08_ui_ux.md) — the locale is fixed rather than user-selectable.
/// The English ARB file is kept as the data/reference locale so the
/// architecture stays ready for a future language switch without a UI
/// rewrite.
class PirithPothaApp extends StatefulWidget {
  const PirithPothaApp({
    required this.authBloc,
    required this.catalogueBloc,
    required this.playerBloc,
    required this.downloadBloc,
    required this.favoritesBloc,
    required this.historyBloc,
    required this.premiumBloc,
    super.key,
  });

  final AuthBloc authBloc;
  final CatalogueBloc catalogueBloc;
  final PlayerBloc playerBloc;
  final DownloadBloc downloadBloc;
  final FavoritesBloc favoritesBloc;
  final HistoryBloc historyBloc;
  final PremiumBloc premiumBloc;

  @override
  State<PirithPothaApp> createState() => _PirithPothaAppState();
}

class _PirithPothaAppState extends State<PirithPothaApp> {
  late final _router = buildAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: widget.authBloc),
        BlocProvider<CatalogueBloc>.value(value: widget.catalogueBloc),
        BlocProvider<PlayerBloc>.value(value: widget.playerBloc),
        BlocProvider<DownloadBloc>.value(value: widget.downloadBloc),
        BlocProvider<FavoritesBloc>.value(value: widget.favoritesBloc),
        BlocProvider<HistoryBloc>.value(value: widget.historyBloc),
        BlocProvider<PremiumBloc>.value(value: widget.premiumBloc),
      ],
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: const Locale('si'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
