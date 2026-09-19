import 'package:flutter_test/flutter_test.dart';

import 'package:vitals/main.dart';

void main() {
  testWidgets('shows the Vitals login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VitalsApp());

    expect(find.text('Vitals'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
  });
}
