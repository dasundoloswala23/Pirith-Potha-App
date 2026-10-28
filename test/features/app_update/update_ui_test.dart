import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pitithpotha/core/l10n/app_localizations.dart';
import 'package:pitithpotha/core/l10n/language_cubit.dart';
import 'package:pitithpotha/features/app_update/domain/entities/version_config.dart';
import 'package:pitithpotha/features/app_update/presentation/bloc/app_update_cubit.dart';
import 'package:pitithpotha/features/app_update/presentation/widgets/mandatory_update_screen.dart';
import 'package:pitithpotha/features/app_update/presentation/widgets/optional_update_dialog.dart';
import 'package:pitithpotha/features/app_update/presentation/widgets/optional_update_prompter.dart';
import 'package:pitithpotha/features/app_update/presentation/widgets/update_gate.dart';
import 'package:pitithpotha/features/history/domain/usecases/record_played.dart';
import 'package:pitithpotha/features/player/domain/usecases/pause_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_pirith.dart';
import 'package:pitithpotha/features/player/domain/usecases/play_queue.dart';
import 'package:pitithpotha/features/player/domain/usecases/resume_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/seek_playback.dart';
import 'package:pitithpotha/features/player/domain/usecases/set_playback_mode.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_next.dart';
import 'package:pitithpotha/features/player/domain/usecases/skip_to_previous.dart';
import 'package:pitithpotha/features/player/domain/usecases/stop_playback.dart';
import 'package:pitithpotha/features/player/presentation/bloc/player_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_audio_repository.dart';
import '../../fakes/fake_history_repository.dart';
import '../../fakes/fake_version_config_repository.dart';

const _home = Key('home');

Future<AppUpdateCubit> _pump(WidgetTester tester, String latest) async {
  SharedPreferences.setMockInitialValues({});
  final language = LanguageCubit(await SharedPreferences.getInstance());
  addTearDown(language.close);

  final audio = FakeAudioRepository();
  final player = PlayerBloc(
    audioRepository: audio,
    playPirith: PlayPirith(audio),
    playQueue: PlayQueue(audio),
    skipToNext: SkipToNext(audio),
    skipToPrevious: SkipToPrevious(audio),
    setPlaybackMode: SetPlaybackMode(audio),
    pausePlayback: PausePlayback(audio),
    resumePlayback: ResumePlayback(audio),
    seekPlayback: SeekPlayback(audio),
    stopPlayback: StopPlayback(audio),
    recordPlayed: RecordPlayed(FakeHistoryRepository()),
  );
  addTearDown(player.close);

  final cubit = AppUpdateCubit(
    repository: FakeVersionConfigRepository(
      VersionConfig(
        latestVersion: latest,
        releaseNotesEnglish: 'Faster downloads',
      ),
    ),
    installedVersion: () async => '1.00.03',
    storeUrl: () => 'https://play.google.com/store/apps/details?id=x',
    // The store "fails to open", to exercise the error path.
    launchUrl: (_) async => false,
  );
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: language),
        BlocProvider.value(value: player),
        BlocProvider.value(value: cubit),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => UpdateGate(child: child!),
        home: const OptionalUpdatePrompter(
          child: Scaffold(body: Text('Home', key: _home)),
        ),
      ),
    ),
  );
  await cubit.check();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return cubit;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('no update: the app shows, nothing else', (tester) async {
    await _pump(tester, '1.00.03');
    expect(find.byKey(_home), findsOneWidget);
    expect(find.byType(OptionalUpdateDialog), findsNothing);
    expect(find.byType(MandatoryUpdateScreen), findsNothing);
  });

  testWidgets('patch: optional dialog with notes; Later dismisses for the '
      'rest of the session', (tester) async {
    final cubit = await _pump(tester, '1.00.04');

    expect(find.byType(OptionalUpdateDialog), findsOneWidget);
    expect(find.text('Version 1.00.04'), findsOneWidget);
    expect(find.text('Faster downloads'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);

    await tester.tap(find.text('Maybe Later'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OptionalUpdateDialog), findsNothing);
    expect(find.byKey(_home), findsOneWidget);

    // A second check in the same session doesn't bring it back.
    await cubit.check();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OptionalUpdateDialog), findsNothing);
  });

  testWidgets('minor/major: blocking screen replaces the app, with no way '
      'out', (tester) async {
    await _pump(tester, '1.01.00');

    expect(find.byType(MandatoryUpdateScreen), findsOneWidget);
    expect(find.byKey(_home), findsNothing, reason: 'app is not in the tree');
    expect(find.text('Maybe Later'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.text('Update Now'), findsOneWidget);

    final popScope = tester.widget<PopScope>(
      find.ancestor(
        of: find.byType(MandatoryUpdateScreen),
        matching: find.byType(PopScope),
      ),
    );
    expect(popScope.canPop, isFalse);
  });

  testWidgets('mandatory: a store that fails to open shows an error and '
      'keeps the block', (tester) async {
    await _pump(tester, '2.00.00');

    await tester.tap(find.text('Update Now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text("Couldn't open the store. Please try again."),
      findsOneWidget,
    );
    expect(find.byType(MandatoryUpdateScreen), findsOneWidget);
  });

  testWidgets('optional: a store that fails to open keeps the dialog with '
      'an error', (tester) async {
    await _pump(tester, '1.00.04');

    await tester.tap(find.text('Update Now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(OptionalUpdateDialog), findsOneWidget);
    expect(
      find.text("Couldn't open the store. Please try again."),
      findsOneWidget,
    );
  });
}
