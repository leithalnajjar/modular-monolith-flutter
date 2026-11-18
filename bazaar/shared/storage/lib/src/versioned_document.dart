// shared/storage/lib/src/versioned_document.dart
import 'dart:convert';

import 'key_value_store.dart';

/// Turns a document of one version into the next version.
typedef Migration = Map<String, Object?> Function(Map<String, Object?> data);

/// A JSON document stored under one key, with a schema version.
///
/// Stored as `{"v": <version>, "data": {...}}`. Reading an older version
/// runs the migrations one step at a time (1 to 2, 2 to 3, ...) and saves
/// the upgraded document, so each migration runs once per device.
final class VersionedDocument {
  VersionedDocument(
    this._store,
    this.key, {
    required this.version,
    this.migrations = const {},
  }) : assert(version >= 1);

  final KeyValueStore _store;
  final String key;

  /// The version this code writes.
  final int version;

  /// `migrations[n]` upgrades a version-n document to version n + 1.
  final Map<int, Migration> migrations;

  /// The stored data at [version], or null when there is nothing usable:
  /// no document, unreadable JSON, a missing migration, or a document
  /// written by a newer version of the app.
  Future<Map<String, Object?>?> read() async {
    final raw = await _store.read(key);
    if (raw == null) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded
        case {'v': final int stored, 'data': final Map<String, Object?> data}) {
      if (stored > version) return null; // written by a newer app version
      var current = data;
      for (var v = stored; v < version; v++) {
        final migrate = migrations[v];
        if (migrate == null) return null;
        current = migrate(current);
      }
      if (stored < version) await write(current);
      return current;
    }
    return null;
  }

  Future<void> write(Map<String, Object?> data) =>
      _store.write(key, jsonEncode({'v': version, 'data': data}));

  Future<void> delete() => _store.delete(key);
}
