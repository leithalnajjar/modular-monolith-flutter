/// Where modules keep data between app launches.
///
/// The app chooses the adapter (shared_preferences on phones, memory in
/// tests). Modules see only their own scope of it.
library;

export 'src/key_value_store.dart';
export 'src/scoped_store.dart';
export 'src/versioned_document.dart';
