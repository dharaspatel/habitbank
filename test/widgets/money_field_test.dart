import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitbank/widgets/money_field.dart';

void main() {
  testWidgets('digits get pushed onto the cents register', (tester) async {
    var current = 0;
    Widget build(int cents) => CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: MoneyField(
                cents: cents,
                onChanged: (v) => current = v,
              ),
            ),
          ),
        );

    await tester.pumpWidget(build(0));
    expect(find.text(r'$0.00'), findsOneWidget);

    final field = find.byType(CupertinoTextField);

    await tester.enterText(field, '1');
    await tester.pump();
    expect(current, 1);
    expect(find.text(r'$0.01'), findsOneWidget);

    await tester.enterText(field, '150');
    await tester.pump();
    expect(current, 150);
    expect(find.text(r'$1.50'), findsOneWidget);

    await tester.enterText(field, '12345');
    await tester.pump();
    expect(current, 12345);
    expect(find.text(r'$123.45'), findsOneWidget);
  });

  test('formatCents renders dollars and cents', () {
    expect(formatCents(0), r'$0.00');
    expect(formatCents(5), r'$0.05');
    expect(formatCents(100), r'$1.00');
    expect(formatCents(12345), r'$123.45');
  });
}
