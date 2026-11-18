import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';

/// Identifies a successful payment. Issued by the payments module.
extension type const PaymentId(String value) {}

/// Proof that money was taken.
final class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.amount,
    required this.at,
  });

  final PaymentId id;
  final Money amount;
  final DateTime at;
}

/// Taking money. The only thing other modules may ask of payments.
abstract interface class Payments {
  /// Charges [amount] once for [reference].
  ///
  /// [reference] is the caller's own identifier for what is being paid
  /// for, such as an order ID. Charging the same reference again returns
  /// the first receipt instead of taking the money twice, so callers can
  /// safely retry after a timeout.
  ///
  /// Fails with [RuleViolation] when the payment is declined and with
  /// [Unavailable] when the provider cannot be reached.
  Future<Result<PaymentReceipt>> charge(Money amount,
      {required String reference});
}

/// A charge was declined. Published by the payments module.
final class PaymentFailed extends DomainEvent {
  const PaymentFailed({
    required this.reference,
    required this.reason,
    required DateTime at,
  }) : super(at);

  final String reference;
  final String reason;
}
