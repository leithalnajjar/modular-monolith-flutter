import 'failure.dart';

/// The outcome of an operation that can fail: either [Ok] with a value or
/// [Err] with a [Failure].
///
/// Because the class is sealed, a `switch` over a [Result] must handle both
/// cases, and the compiler tells you when you forget one.
sealed class Result<T> {
  const Result();

  /// Wraps a successful value.
  const factory Result.ok(T value) = Ok<T>;

  /// Wraps a failure.
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;

  /// Returns the value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  /// Transforms the value, keeping failures untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value) => Result.ok(transform(value)),
        Err(:final failure) => Result.err(failure),
      };

  /// Chains another operation that can fail.
  Future<Result<R>> then<R>(Future<Result<R>> Function(T value) next) async =>
      switch (this) {
        Ok(:final value) => await next(value),
        Err(:final failure) => Result.err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;

  @override
  String toString() => 'Err($failure)';
}
