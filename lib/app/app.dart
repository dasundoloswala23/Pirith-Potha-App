import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/ads/ad_service.dart';
import '../core/ads/player_exit_ad_observer.dart';
import '../core/l10n/app_localizations.dart';
import '../core/l10n/language_cubit.dart';
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
/// The interface is English with no in-app language switcher (see
/// docs/08_ui_ux.md) — the locale is fixed rather than user-selectable.
/// Sinhala is reserved for Pirith content itself (chant names and
/// descriptions, which come from Firestore). The Sinhala ARB file is kept
/// complete and in sync so a future language switch needs no UI rewrite.
class PirithPothaApp extends StatefulWidget {
  const PirithPothaApp({
    required this.authBloc,
    required this.catalogueBloc,
    required this.playerBloc,
    required this.downloadBloc,
    required this.favoritesBloc,
    required this.historyBloc,
    required this.premiumBloc,
    required this.languageCubit,
    this.adService,
    super.key,
  });

  final AuthBloc authBloc;
  final CatalogueBloc catalogueBloc;
  final PlayerBloc playerBloc;
  final DownloadBloc downloadBloc;
  final FavoritesBloc favoritesBloc;
  final HistoryBloc historyBloc;
  final PremiumBloc premiumBloc;
  final LanguageCubit languageCubit;

  /// Null in widget tests, which build the app without the ad SDK; the
  /// player-exit interstitial is simply not wired up in that case.
  final AdService? adService;

  @override
  State<PirithPothaApp> createState() => _PirithPothaAppState();
}

class _PirithPothaAppState extends State<PirithPothaApp> {
  late final _router = buildAppRouter(
    adObserver: widget.adService == null
        ? null
        : PlayerExitAdObserver(
            ads: widget.adService!,
            isAudioPlaying: () {
              final state = widget.playerBloc.state;
              return state is PlayerActive && state.isPlaying;
            },
          ),
  );

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
        BlocProvider<LanguageCubit>.value(value: widget.languageCubit),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: const Locale('en'),
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
