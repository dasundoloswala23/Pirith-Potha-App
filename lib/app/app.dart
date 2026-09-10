import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class PirithPothaApp extends StatefulWidget {
  const PirithPothaApp({super.key});

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
    return ValueListenableBuilder<Locale>(
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
    );
  }
}
