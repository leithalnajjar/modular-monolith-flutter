// shared/feature_flags/lib/src/flags.dart

/// A switch for one feature, declared as a constant by the module that
/// owns the feature.
final class Flag {
  const Flag(
    this.name, {
    required this.description,
    this.defaultValue = false,
  });

  /// `<owner>.<feature>`, such as `cart.persist`. The owner is a module's
  /// name, or `app` for switches the composition root owns.
  final String name;

  /// Why the flag exists and when it can be removed. Shown in reviews and
  /// in flag listings, so write it for someone who has never seen the code.
  final String description;

  /// The value when nobody set one. Choose the value that is safe if the
  /// configuration never arrives.
  final bool defaultValue;

  /// The part of [name] before the first dot.
  String get owner => name.split('.').first;

  @override
  String toString() => 'Flag($name)';
}

/// Reads flags. What modules depend on.
abstract interface class FeatureFlags {
  bool isOn(Flag flag);
}

/// Flag values fixed for the whole run of the app.
///
/// Decided once, at startup, from the build's configuration and (in a real
/// app) a remote configuration service. Values never change while the app
/// runs, so a screen never changes under the user's finger.
final class FlagValues implements FeatureFlags {
  const FlagValues([this.values = const {}]);

  /// Parses `cart.persist=false,app.inbox=true`. Whitespace is ignored and
  /// an empty string means no values.
  factory FlagValues.parse(String text) {
    final values = <String, bool>{};
    for (final entry in text.split(',')) {
      if (entry.trim().isEmpty) continue;
      final parts = entry.split('=').map((p) => p.trim()).toList();
      final value = switch (parts) {
        [final _, 'true'] => true,
        [final _, 'false'] => false,
        _ => throw FormatException(
            'Expected name=true or name=false, got "${entry.trim()}"'),
      };
      values[parts.first] = value;
    }
    return FlagValues(values);
  }

  final Map<String, bool> values;

  @override
  bool isOn(Flag flag) => values[flag.name] ?? flag.defaultValue;

  /// Names that have a value here but are not in [declared]: usually a
  /// typo, or a flag that was removed from the code but not from the
  /// configuration.
  Set<String> undeclared(Iterable<Flag> declared) =>
      values.keys.toSet().difference({for (final f in declared) f.name});
}
