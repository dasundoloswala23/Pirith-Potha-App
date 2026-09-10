import 'package:flutter_test/flutter_test.dart';

import 'package:pitithpotha/app/app.dart';

void main() {
  testWidgets('App launches to the Home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const PirithPothaApp());
    await tester.pumpAndSettle();

    expect(find.byType(PirithPothaApp), findsOneWidget);
  });
}
