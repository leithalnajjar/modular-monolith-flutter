// modules/cart/lib/src/data/cart_persistence.dart
import 'dart:async';

import 'package:cart_api/cart_api.dart';

import '../cart_service.dart';
import 'cart_storage.dart';

/// Keeps the cart between app launches.
///
/// Restores the saved cart when the module starts, then saves every change.
/// The service itself knows nothing about storage: its rules stay easy to
/// test, and persistence can be switched off by not starting this class.
final class CartPersistence {
  CartPersistence(this._storage, this._service);

  final CartStorage _storage;
  final CartService _service;
  StreamSubscription<Cart>? _subscription;

  /// Writes happen one after another, in the order the changes happened,
  /// so an older cart can never overwrite a newer one.
  Future<void> _lastWrite = Future.value();

  Future<void> start() async {
    final saved = await _storage.load(currency: _service.current.currency);
    if (saved != null) _service.restore(saved);

    _subscription = _service.changes.listen((cart) {
      _lastWrite = _lastWrite.then((_) =>
          // An empty cart leaves nothing behind, which also means nothing
          // of the previous user is left after sign-out.
          cart.isEmpty ? _storage.clear() : _storage.save(cart));
    });
  }

  /// Completes when every change so far has been written.
  Future<void> get flushed => _lastWrite;

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _lastWrite;
  }
}
