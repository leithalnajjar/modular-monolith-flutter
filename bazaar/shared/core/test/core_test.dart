import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('adds amounts in the same currency', () {
      expect(const Money(1050, 'USD') + const Money(250, 'USD'),
          const Money(1300, 'USD'));
    });

    test('refuses to mix currencies', () {
      expect(() => const Money(100, 'USD') + const Money(100, 'EUR'),
          throwsArgumentError);
    });

    test('multiplies by quantity without floating point errors', () {
      expect(const Money(10, 'USD').times(3), const Money(30, 'USD'));
    });

    test('prints a simple display string', () {
      expect(const Money(1250, 'USD').toString(), 'USD 12.50');
      expect(const Money(-5, 'USD').toString(), 'USD -0.05');
    });
  });

  group('Result', () {
    test('map transforms Ok and keeps Err', () {
      const ok = Result<int>.ok(2);
      const err = Result<int>.err(NotFound('nope'));
      expect(ok.map((v) => v * 10).valueOrNull, 20);
      expect(err.map((v) => v * 10).valueOrNull, isNull);
    });

    test('then chains async operations and stops at the first failure',
        () async {
      Future<Result<int>> half(int v) async => v.isEven
          ? Result.ok(v ~/ 2)
          : const Result.err(RuleViolation('odd'));

      final good = await const Result<int>.ok(8).then(half);
      final bad = await const Result<int>.ok(3).then(half);

      expect(good.valueOrNull, 4);
      expect(bad, isA<Err<int>>());
    });

    test('a switch must handle both cases', () {
      String describe(Result<int> r) => switch (r) {
            Ok(:final value) => 'ok $value',
            Err(:final failure) => 'failed: ${failure.message}',
          };
      expect(describe(const Result.ok(1)), 'ok 1');
      expect(describe(const Result.err(Unauthorized('sign in'))),
          'failed: sign in');
    });
  });

  test('FixedClock only moves when told to', () {
    final clock = FixedClock(DateTime.utc(2027, 1, 1));
    clock.advance(const Duration(hours: 2));
    expect(clock.now(), DateTime.utc(2027, 1, 1, 2));
  });
}
