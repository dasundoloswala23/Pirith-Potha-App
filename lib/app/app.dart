import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/pirith/presentation/bloc/catalogue_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// [authBloc]/[catalogueBloc] are injected rather than pulled from the
/// global service locator here, so widget tests can supply
/// fake-repository-backed instances instead of needing a live Firebase
/// connection.
class PirithPothaApp extends StatefulWidget {
  const PirithPothaApp({
    required this.authBloc,
    required this.catalogueBloc,
    super.key,
  });

  final AuthBloc authBloc;
  final CatalogueBloc catalogueBloc;

  @override
  State<PirithPothaApp> createState() => _PirithPothaAppState();
}

class _PirithPothaAppState extends State<PirithPothaApp> {
  final _localeController = LocaleController(LocaleController.sinhala);
  late final _router = buildAppRouter(localeController: _localeController);

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: widget.authBloc),
        BlocProvider<CatalogueBloc>.value(value: widget.catalogueBloc),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: _localeController,
        builder: (context, locale, _) {
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
