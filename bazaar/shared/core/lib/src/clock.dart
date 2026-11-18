/// The current time, behind an interface so tests can control it.
abstract interface class Clock {
  DateTime now();
}

/// The real clock, used by the app.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock that only moves when a test tells it to.
final class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}
