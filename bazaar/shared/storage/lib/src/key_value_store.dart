// shared/storage/lib/src/key_value_store.dart

/// Small amounts of text kept between app launches.
///
/// A port: it says what modules need, not how it is done. The app passes an
/// adapter (shared_preferences on phones, a file on desktop, memory in
/// tests) to the module host.
abstract interface class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// Every key currently stored.
  Future<Set<String>> keys();
}

/// Keeps everything in a map. For tests, demos, and the first chapters.
final class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String> initial = const {}])
      : _values = {...initial};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<Set<String>> keys() async => {..._values.keys};
}
