import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets(
    'GymFlow inicia correctamente',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const GymFlowApp(),
      );

      expect(
        find.byType(GymFlowApp),
        findsOneWidget,
      );
    },
  );
}