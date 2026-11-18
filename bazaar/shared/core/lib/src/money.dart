/// An amount of money in one currency, stored in minor units (cents).
///
/// Never use `double` for money: 0.1 + 0.2 is not 0.3 in binary floating
/// point, and the cent that goes missing always belongs to a customer.
final class Money implements Comparable<Money> {
  const Money(this.minorUnits, this.currency)
      : assert(currency.length == 3, 'Use ISO 4217 codes such as USD');

  const Money.zero(this.currency) : minorUnits = 0;

  /// Amount in the smallest unit of the currency (cents for USD).
  final int minorUnits;

  /// ISO 4217 code, for example `USD` or `EUR`.
  final String currency;

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;

  Money operator +(Money other) {
    _checkSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _checkSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  /// Multiplies by a whole quantity, such as the number of items in a line.
  Money times(int quantity) => Money(minorUnits * quantity, currency);

  @override
  int compareTo(Money other) {
    _checkSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  void _checkSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
          'Cannot combine $currency with ${other.currency} without conversion');
    }
  }

  /// A simple, locale-free display such as `USD 12.50`. The UI kit owns
  /// proper localized formatting.
  @override
  String toString() {
    final sign = minorUnits < 0 ? '-' : '';
    final abs = minorUnits.abs();
    final whole = abs ~/ 100;
    final cents = (abs % 100).toString().padLeft(2, '0');
    return '$currency $sign$whole.$cents';
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);
}
