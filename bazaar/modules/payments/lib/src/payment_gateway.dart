import 'package:core/core.dart';

/// The port between payments and a payment provider (Stripe, Adyen, a bank,
/// an in-app purchase API). One adapter per provider; payments' own rules
/// never change when the provider does.
abstract interface class PaymentGateway {
  /// Asks the provider to take [amount]. Providers deduplicate by
  /// [idempotencyKey]: sending the same key twice charges at most once.
  Future<GatewayOutcome> charge(Money amount, {required String idempotencyKey});
}

/// Everything a provider can answer, in payments' own words.
sealed class GatewayOutcome {
  const GatewayOutcome();
}

/// The money was taken.
final class Approved extends GatewayOutcome {
  const Approved(this.transactionId);
  final String transactionId;
}

/// The provider refused: insufficient funds, a blocked card, fraud checks.
final class Declined extends GatewayOutcome {
  const Declined(this.reason);
  final String reason;
}

/// We do not know what happened: timeout, no network, provider error.
/// The charge may or may not have gone through.
final class Unreachable extends GatewayOutcome {
  const Unreachable([this.cause]);
  final Object? cause;
}
