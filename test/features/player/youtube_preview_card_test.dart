import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/l10n/app_localizations.dart';
import 'package:pitithpotha/features/player/presentation/widgets/youtube_preview_card.dart';

// Note for anyone extending this: do NOT add an assertion that the thumbnail
// renders. Flutter's test HttpClient answers every request with an empty 400,
// so every Image.network in a widget test resolves through errorBuilder no
// matter what URL it is given. That makes the failure-path assertions below
// meaningful and would make a success-path assertion a lie.
Future<void> _pump(WidgetTester tester, String url) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: YouTubePreviewCard(youtubeUrl: url)),
    ),
  );
}

void main() {
  testWidgets('an unparseable link still renders a tappable card', (
    tester,
  ) async {
    // The admin field takes free text, so this is a realistic value. The
    // point of the card is that the link is never lost, even then.
    await _pump(tester, 'not a youtube link');
    await tester.pump();

    expect(find.text('Watch on YouTube'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    // No id resolved, so nothing should even attempt to load.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('a real link attempts a thumbnail', (tester) async {
    await _pump(tester, 'https://youtu.be/dQw4w9WgXcQ');
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Watch on YouTube'), findsOneWidget);
  });

  testWidgets('the card holds 16:9 regardless of the link', (tester) async {
    await _pump(tester, 'https://youtu.be/dQw4w9WgXcQ');
    await tester.pump();

    final size = tester.getSize(find.byType(AspectRatio));
    expect(size.width / size.height, closeTo(16 / 9, 0.01));
  });
}
