import 'package:feature_flags/feature_flags.dart';
import 'package:test/test.dart';

const _persist = Flag('cart.persist',
    description: 'Keep the cart between launches.', defaultValue: true);
const _express = Flag('checkout.express', description: 'One-tap checkout.');

void main() {
  test('unset flags use their default', () {
    const flags = FlagValues();
    expect(flags.isOn(_persist), isTrue);
    expect(flags.isOn(_express), isFalse);
  });

  test('parses name=value lists', () {
    final flags =
        FlagValues.parse(' cart.persist=false, checkout.express=true ');
    expect(flags.isOn(_persist), isFalse);
    expect(flags.isOn(_express), isTrue);
    expect(FlagValues.parse('').values, isEmpty);
  });

  test('rejects values that are not true or false', () {
    expect(() => FlagValues.parse('cart.persist=yes'), throwsFormatException);
    expect(() => FlagValues.parse('cart.persist'), throwsFormatException);
  });

  test('finds values for flags nobody declares', () {
    final flags = FlagValues.parse('cart.persits=false,cart.persist=true');
    expect(flags.undeclared([_persist, _express]), {'cart.persits'});
  });

  test('the owner is the part before the first dot', () {
    expect(_persist.owner, 'cart');
  });
}
