/// A typed, in-process event bus.
///
/// Modules publish facts that already happened ("OrderPlaced") and other
/// modules react without the publisher knowing who is listening.
library;

import 'dart:async';

/// Base type for every event that crosses a module boundary.
///
/// Events are named in the past tense and carry only what listeners need,
/// usually IDs and a few values, never live objects from the publisher.
abstract class DomainEvent {
  const DomainEvent(this.occurredAt);
  final DateTime occurredAt;
}

/// Called when a subscriber throws, so one broken module cannot stop
/// events from reaching the others.
typedef SubscriberErrorHandler = void Function(
    DomainEvent event, Object error, StackTrace stack);

final class EventBus {
  EventBus({SubscriberErrorHandler? onSubscriberError})
      : _onSubscriberError = onSubscriberError ?? _ignore;

  final SubscriberErrorHandler _onSubscriberError;
  final _subscribers = <_Subscriber>[];
  bool _closed = false;

  /// Registers [handler] for events of type [E] (and its subtypes).
  ///
  /// Returns a [Subscription] that the module must cancel when it stops.
  Subscription on<E extends DomainEvent>(
      FutureOr<void> Function(E event) handler) {
    final subscriber = _Subscriber(
      accepts: (event) => event is E,
      handle: (event) => handler(event as E),
    );
    _subscribers.add(subscriber);
    return Subscription._(() => _subscribers.remove(subscriber));
  }

  /// Delivers [event] to every matching subscriber, one after another, in
  /// the order they subscribed. Completes when all handlers have finished.
  Future<void> publish(DomainEvent event) async {
    if (_closed) {
      throw StateError('EventBus is closed');
    }
    // Copy the list: a handler may subscribe or cancel while we iterate.
    for (final subscriber in List.of(_subscribers)) {
      if (!subscriber.accepts(event)) continue;
      try {
        await subscriber.handle(event);
      } catch (error, stack) {
        _onSubscriberError(event, error, stack);
      }
    }
  }

  /// Number of active subscriptions, useful in tests and leak checks.
  int get subscriberCount => _subscribers.length;

  void close() {
    _closed = true;
    _subscribers.clear();
  }

  static void _ignore(DomainEvent event, Object error, StackTrace stack) {}
}

final class Subscription {
  Subscription._(this._cancel);
  final bool Function() _cancel;

  /// Stops receiving events. Safe to call more than once.
  void cancel() => _cancel();
}

final class _Subscriber {
  _Subscriber({required this.accepts, required this.handle});
  final bool Function(DomainEvent event) accepts;
  final FutureOr<void> Function(DomainEvent event) handle;
}
