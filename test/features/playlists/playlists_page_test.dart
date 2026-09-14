import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/l10n/app_localizations.dart';
import 'package:pitithpotha/core/l10n/language_cubit.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_active_pirith.dart';
import 'package:pitithpotha/features/pirith/domain/usecases/get_categories.dart';
import 'package:pitithpotha/features/pirith/presentation/bloc/catalogue_bloc.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/add_pirith_to_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/create_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/delete_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/remove_pirith_from_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/rename_playlist.dart';
import 'package:pitithpotha/features/playlists/domain/usecases/reorder_playlist.dart';
import 'package:pitithpotha/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:pitithpotha/features/playlists/presentation/pages/playlists_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_pirith_repository.dart';
import '../../fakes/fake_playlist_repository.dart';

void main() {
  // Opening the create dialog reads the language preference from a callback,
  // not from build. `Bilingual.of` uses `context.watch`, which asserts there
  // — and the assert only fires at runtime, so nothing but actually tapping
  // the button catches it. That shipped once; this test is why it can't
  // again.
  testWidgets('tapping "new playlist" opens the name dialog', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final languageCubit = LanguageCubit(await SharedPreferences.getInstance());
    addTearDown(languageCubit.close);

    final repository = FakePlaylistRepository();
    final playlistBloc = PlaylistBloc(
      playlistRepository: repository,
      createPlaylist: CreatePlaylist(repository),
      renamePlaylist: RenamePlaylist(repository),
      deletePlaylist: DeletePlaylist(repository),
      addPirithToPlaylist: AddPirithToPlaylist(repository),
      removePirithFromPlaylist: RemovePirithFromPlaylist(repository),
      reorderPlaylist: ReorderPlaylist(repository),
    );
    addTearDown(playlistBloc.close);

    // Once a playlist exists the page renders its populated branch, which
    // resolves covers through the catalogue.
    final pirithRepository = FakePirithRepository();
    final catalogueBloc = CatalogueBloc(
      getCategories: GetCategories(pirithRepository),
      getActivePirith: GetActivePirith(pirithRepository),
    )..add(const CatalogueStarted());
    addTearDown(catalogueBloc.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<LanguageCubit>.value(value: languageCubit),
          BlocProvider<PlaylistBloc>.value(value: playlistBloc),
          BlocProvider<CatalogueBloc>.value(value: catalogueBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlaylistsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Asserted by what the user sees, not by the Material class backing it:
    // the dialog has since been restyled from AlertDialog to Dialog, and a
    // test that fails on that is testing the wrong thing.
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Save'), findsOneWidget);

    // Saving must survive the dialog's *exit* transition: the fields are
    // still mounted and still rebuilding while it animates out, so
    // controllers disposed the moment the future completes throw "used
    // after being disposed". pumpAndSettle runs that animation to the end,
    // which is the only way this surfaces.
    await tester.enterText(find.byType(TextField).first, 'උදෑසන පිරිත්');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);

    final state = playlistBloc.state as PlaylistsLoaded;
    expect(state.playlists.single.name, 'උදෑසන පිරිත්');
  });
}
