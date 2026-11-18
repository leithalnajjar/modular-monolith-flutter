import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('formatMoney', () {
    test('uses the currency symbol and its own decimal places', () {
      expect(formatMoney(const Money(4900, 'USD')), r'$49.00');
      expect(formatMoney(const Money(1250, 'EUR')), '€12.50');
      expect(formatMoney(const Money(1800, 'JPY')), '¥1,800');
    });

    test('follows the locale for separators', () {
      // German puts a non-breaking space (U+00A0) before the symbol, so
      // the amount and the € never end up on different lines.
      expect(formatMoney(const Money(123456, 'EUR'), locale: 'de_DE'),
          '1.234,56\u00a0€');
    });
  });

  test('formatDate writes dates the way people read them', () {
    // A local time, so the result is the same in every time zone.
    expect(formatDate(DateTime(2027, 6, 1, 12)), 'Jun 1, 2027');
  });

  Widget wrap(Widget child) =>
      MaterialApp(theme: bazaarTheme(), home: Scaffold(body: child));

  testWidgets('ErrorState offers Retry only when it can retry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
        wrap(ErrorState(message: 'Offline', onRetry: () => retried = true)));
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);

    await tester.pumpWidget(wrap(const ErrorState(message: 'Offline')));
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('PriceText adds an optional prefix', (tester) async {
    await tester.pumpWidget(
        wrap(const PriceText(Money(9800, 'USD'), prefix: 'Total ')));
    expect(find.text(r'Total $98.00'), findsOneWidget);
  });
}
