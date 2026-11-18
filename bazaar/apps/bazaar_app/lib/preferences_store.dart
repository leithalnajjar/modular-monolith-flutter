// apps/bazaar_app/lib/preferences_store.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';

/// The real storage adapter: the platform's preferences (DataStore on
/// Android, UserDefaults on iOS and macOS, a file on desktop, localStorage
/// on the web).
///
/// It lives in the app, not in a module or in shared/storage: choosing a
/// storage technology is the composition root's decision, and only the app
/// depends on the plugin.
final class PreferencesStore implements KeyValueStore {
  PreferencesStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> delete(String key) => _preferences.remove(key);

  @override
  Future<Set<String>> keys() => _preferences.getKeys();
}
