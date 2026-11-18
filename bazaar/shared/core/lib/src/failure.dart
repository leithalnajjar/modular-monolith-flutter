/// A failure that crossed a module boundary.
///
/// Modules never throw their internal exceptions at each other. They return
/// a [Failure] inside a [Result] instead, so the caller can decide what to do.
sealed class Failure {
  const Failure(this.message);

  /// A developer-facing explanation. Not shown to users as-is.
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// The thing that was asked for does not exist.
final class NotFound extends Failure {
  const NotFound(super.message);
}

/// The caller is not allowed to do this (for example, not signed in).
final class Unauthorized extends Failure {
  const Unauthorized(super.message);
}

/// The request broke a business rule (for example, an empty cart at checkout).
final class RuleViolation extends Failure {
  const RuleViolation(super.message);
}

/// Something outside our control failed: network, disk, a payment gateway.
final class Unavailable extends Failure {
  const Unavailable(super.message, {this.cause});

  /// The original error, kept for logging only.
  final Object? cause;
}
