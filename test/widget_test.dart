import 'package:flutter_test/flutter_test.dart';

import 'package:habitbank/app.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitBankApp());
    await tester.pump();
  });
}
