import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payments/payments.dart';
import 'package:payments/src/payment_service.dart';
import 'package:payments_api/payments_api.dart';

void main() {
  late EventBus bus;
  late List<DomainEvent> published;

  setUp(() {
    bus = EventBus();
    published = [];
    bus.on<DomainEvent>(published.add);
  });

  PaymentService service(FakePaymentGateway gateway) =>
      PaymentService(gateway, bus, FixedClock(DateTime.utc(2027, 5, 1)));

  test('approves and returns a receipt', () async {
    final result = await service(FakePaymentGateway())
        .charge(const Money(4900, 'USD'), reference: 'o-1');

    expect(result.valueOrNull?.id, const PaymentId('pay-1'));
    expect(result.valueOrNull?.amount, const Money(4900, 'USD'));
  });

  test('charging the same reference twice takes the money once', () async {
    final gateway = FakePaymentGateway();
    final payments = service(gateway);

    final first = await payments.charge(const Money(100, 'USD'), reference: 'o-1');
    final second = await payments.charge(const Money(100, 'USD'), reference: 'o-1');

    expect(second.valueOrNull?.id, first.valueOrNull?.id);
    expect(gateway.chargeCount, 1);
  });

  test('a declined card is a rule violation and announces PaymentFailed',
      () async {
    final result = await service(
            FakePaymentGateway(declineAbove: const Money(5000, 'USD')))
        .charge(const Money(9900, 'USD'), reference: 'o-2');

    final failure = (result as Err<PaymentReceipt>).failure;
    expect(failure, isA<RuleViolation>());
    expect(failure.message, 'Payment declined: Insufficient funds');
    final event = published.single as PaymentFailed;
    expect(event.reference, 'o-2');
  });

  test('a lost answer is Unavailable, and the retry does not charge twice',
      () async {
    final gateway = FakePaymentGateway(lostAnswers: 1);
    final payments = service(gateway);

    final first = await payments.charge(const Money(100, 'USD'), reference: 'o-3');
    expect((first as Err<PaymentReceipt>).failure, isA<Unavailable>());

    final retry = await payments.charge(const Money(100, 'USD'), reference: 'o-3');
    expect(retry.valueOrNull, isNotNull);
    expect(gateway.chargeCount, 1); // the bank took the money exactly once
  });

  test('zero and negative amounts are refused before the gateway', () async {
    final gateway = FakePaymentGateway();
    final result =
        await service(gateway).charge(const Money(0, 'USD'), reference: 'o-4');
    expect((result as Err<PaymentReceipt>).failure, isA<RuleViolation>());
    expect(gateway.chargeCount, 0);
  });
}
