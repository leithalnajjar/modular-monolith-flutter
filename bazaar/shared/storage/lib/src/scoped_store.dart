// shared/storage/lib/src/scoped_store.dart
import 'key_value_store.dart';

/// One module's private part of a [KeyValueStore].
///
/// Every key is stored as `<scope>/<key>`, so modules cannot overwrite each
/// other's data by accident, the keys in the store show who owns them, and
/// [clear] removes one module's data without touching anyone else's.
final class ScopedStore implements KeyValueStore {
  ScopedStore(this._store, this.scope)
      : assert(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(scope),
            'scope must be a module name, such as "cart"');

  final KeyValueStore _store;
  final String scope;

  String get _prefix => '$scope/';

  @override
  Future<String?> read(String key) => _store.read('$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _store.write('$_prefix$key', value);

  @override
  Future<void> delete(String key) => _store.delete('$_prefix$key');

  /// This scope's keys, without the prefix.
  @override
  Future<Set<String>> keys() async => {
        for (final key in await _store.keys())
          if (key.startsWith(_prefix)) key.substring(_prefix.length),
      };

  /// Deletes everything in this scope, and nothing outside it.
  Future<void> clear() async {
    for (final key in await keys()) {
      await delete(key);
    }
  }
}

extension Scopes on KeyValueStore {
  /// The part of this store that belongs to [scope].
  ScopedStore scope(String scope) => ScopedStore(this, scope);
}
