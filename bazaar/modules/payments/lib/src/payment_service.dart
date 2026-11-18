import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:payments_api/payments_api.dart';

import 'payment_gateway.dart';

/// Payments' rules, independent of any provider.
final class PaymentService implements Payments {
  PaymentService(this._gateway, this._bus, this._clock);

  final PaymentGateway _gateway;
  final EventBus _bus;
  final Clock _clock;

  /// Receipts by the caller's reference: the second line of defence
  /// against double charges, after the provider's idempotency key.
  final _receipts = <String, PaymentReceipt>{};

  @override
  Future<Result<PaymentReceipt>> charge(Money amount,
      {required String reference}) async {
    if (amount.minorUnits <= 0) {
      return const Result.err(RuleViolation('Amount must be positive'));
    }
    final known = _receipts[reference];
    if (known != null) return Result.ok(known);

    final outcome = await _gateway.charge(amount, idempotencyKey: reference);
    switch (outcome) {
      case Approved(:final transactionId):
        final receipt = PaymentReceipt(
            id: PaymentId(transactionId), amount: amount, at: _clock.now());
        _receipts[reference] = receipt;
        return Result.ok(receipt);
      case Declined(:final reason):
        await _bus.publish(
            PaymentFailed(reference: reference, reason: reason, at: _clock.now()));
        return Result.err(RuleViolation('Payment declined: $reason'));
      case Unreachable(:final cause):
        return Result.err(Unavailable(
            'We could not confirm the payment. Please try again.',
            cause: cause));
    }
  }
}
