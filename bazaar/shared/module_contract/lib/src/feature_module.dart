import 'dart:async';

import 'package:feature_flags/feature_flags.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:storage/storage.dart';

import 'nav_destination.dart';

/// What every feature module gives the app.
///
/// The app never sees a module's classes. It only sees this interface: a
/// name, a way to register services, the routes the module owns, and two
/// lifecycle hooks.
abstract class FeatureModule {
  const FeatureModule();

  /// A unique, stable name such as `catalog`. Used in logs and errors.
  String get name;

  /// Registers this module's services with [di].
  ///
  /// Called for every module before any module is started, in list order.
  /// Register lazily: do not *resolve* other modules' services here, because
  /// they may not be registered yet.
  void register(GetIt di);

  /// The routes this module owns. Called once, after every module started.
  List<RouteBase> routes(GetIt di) => const [];

  /// An app-wide redirect, checked on every navigation.
  ///
  /// Return a new location to redirect, or `null` to let navigation
  /// continue. Modules are asked in list order; the first non-null answer
  /// wins. Use it for things only this module can decide, such as moving
  /// old URLs to new ones. Guards for a single route belong on that route.
  FutureOr<String?> redirect(GetIt di, GoRouterState state) => null;

  /// Entries for the app's main navigation bar. Called once, after start.
  List<NavDestination> destinations(GetIt di) => const [];

  /// Called after all modules registered. Subscribe to events, warm caches.
  Future<void> start(GetIt di) async {}

  /// The feature flags this module owns (Chapter 21). Each name starts
  /// with the module's [name] and a dot, such as `cart.persist`. Read them
  /// with `di<FeatureFlags>().isOn(flag)`.
  List<Flag> get flags => const [];

  /// This module's private part of the app's storage (Chapter 20). Every
  /// key it writes is stored under the module's [name]. A module never
  /// opens another module's scope: it asks that module through its contract.
  ScopedStore storage(GetIt di) => di<KeyValueStore>().scope(name);

  /// Called when the app shuts down (and between tests), in reverse order.
  /// Cancel subscriptions and close resources here.
  Future<void> stop() async {}
}
