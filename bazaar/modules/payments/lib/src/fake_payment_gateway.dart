import 'package:core/core.dart';

import 'payment_gateway.dart';

/// A gateway that takes no real money, for demos and tests. It behaves like
/// a real provider in the ways that matter: it deduplicates by idempotency
/// key, it can decline, and it can lose its answer after charging.
final class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({this.declineAbove, this.lostAnswers = 0});

  /// Charges above this amount are declined ("insufficient funds").
  final Money? declineAbove;

  /// How many of the next charges succeed at the provider but never reach
  /// us, the way a request times out after the bank already said yes.
  int lostAnswers;

  final _charges = <String, Approved>{};

  /// Number of distinct charges actually taken.
  int get chargeCount => _charges.length;

  @override
  Future<GatewayOutcome> charge(Money amount,
      {required String idempotencyKey}) async {
    final existing = _charges[idempotencyKey];
    if (existing != null) return existing;

    final limit = declineAbove;
    if (limit != null && amount > limit) {
      return const Declined('Insufficient funds');
    }

    final approved = Approved('pay-${_charges.length + 1}');
    _charges[idempotencyKey] = approved;

    if (lostAnswers > 0) {
      lostAnswers--;
      return const Unreachable('The answer was lost on the way back');
    }
    return approved;
  }
}

extension on Money {
  bool operator >(Money other) => compareTo(other) > 0;
}
