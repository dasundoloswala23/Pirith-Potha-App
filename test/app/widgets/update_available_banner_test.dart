import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pitithpotha/app/widgets/update_available_banner.dart';
import 'package:pitithpotha/core/l10n/app_localizations.dart';
import 'package:pitithpotha/core/l10n/language_cubit.dart';
import 'package:pitithpotha/features/app_update/domain/entities/version_config.dart';
import 'package:pitithpotha/features/app_update/domain/repositories/version_config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../fakes/fake_version_config_repository.dart';

Future<void> _pump(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  final languageCubit = LanguageCubit(prefs);
  addTearDown(languageCubit.close);

  await tester.pumpWidget(
    BlocProvider<LanguageCubit>.value(
      value: languageCubit,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: UpdateAvailableBanner()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Pirith Potha',
      packageName: 'com.pirith.pitithpotha',
      version: '1.00.02',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  tearDown(() async {
    if (GetIt.instance.isRegistered<VersionConfigRepository>()) {
      await GetIt.instance.unregister<VersionConfigRepository>();
    }
    if (GetIt.instance.isRegistered<SharedPreferences>()) {
      await GetIt.instance.unregister<SharedPreferences>();
    }
  });

  testWidgets('renders nothing when the installed version is current', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    GetIt.instance
      ..registerSingleton<SharedPreferences>(await SharedPreferences.getInstance())
      ..registerSingleton<VersionConfigRepository>(
        FakeVersionConfigRepository(
          const VersionConfig(latestVersion: '1.00.02'),
        ),
      );

    await _pump(tester);

    expect(find.byType(UpdateAvailableBanner), findsOneWidget);
    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('shows the banner when the installed version is outdated', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    GetIt.instance
      ..registerSingleton<SharedPreferences>(await SharedPreferences.getInstance())
      ..registerSingleton<VersionConfigRepository>(
        FakeVersionConfigRepository(
          const VersionConfig(latestVersion: '1.00.03'),
        ),
      );

    await _pump(tester);

    expect(find.text('Update available'), findsOneWidget);
  });

  testWidgets('dismissing hides it and is remembered for that version', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    GetIt.instance
      ..registerSingleton<SharedPreferences>(prefs)
      ..registerSingleton<VersionConfigRepository>(
        FakeVersionConfigRepository(
          const VersionConfig(latestVersion: '1.00.03'),
        ),
      );

    await _pump(tester);
    expect(find.text('Update available'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsNothing);
    expect(prefs.getString('update_banner_dismissed_version'), '1.00.03');
  });

  testWidgets('a dismissal does not suppress a newer remote version', (
    tester,
  ) async {
    // The remote version bumped again after the user dismissed the old one
    // — the whole point of keying the dismissal to the remote version, not
    // "once per session".
    SharedPreferences.setMockInitialValues({
      'update_banner_dismissed_version': '1.00.03',
    });
    GetIt.instance
      ..registerSingleton<SharedPreferences>(await SharedPreferences.getInstance())
      ..registerSingleton<VersionConfigRepository>(
        FakeVersionConfigRepository(
          const VersionConfig(latestVersion: '1.00.04'),
        ),
      );

    await _pump(tester);

    expect(find.text('Update available'), findsOneWidget);
  });

  testWidgets('a dismissal of the same version stays hidden', (tester) async {
    SharedPreferences.setMockInitialValues({
      'update_banner_dismissed_version': '1.00.03',
    });
    GetIt.instance
      ..registerSingleton<SharedPreferences>(await SharedPreferences.getInstance())
      ..registerSingleton<VersionConfigRepository>(
        FakeVersionConfigRepository(
          const VersionConfig(latestVersion: '1.00.03'),
        ),
      );

    await _pump(tester);

    expect(find.text('Update available'), findsNothing);
  });
}
