import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:storage/storage.dart';

import 'feature_module.dart';
import 'nav_destination.dart';

/// Starts and stops a list of [FeatureModule]s in a predictable order, and
/// builds the app's router from the routes they own.
///
/// The host is the only place where modules meet. It provides the services
/// every module may rely on ([EventBus], [Clock], [KeyValueStore] and
/// [FeatureFlags]) and nothing else.
final class ModuleHost {
  ModuleHost._(this.di, this.modules, this.router, this.destinations);

  /// The container shared by all modules.
  final GetIt di;

  final List<FeatureModule> modules;
  final GoRouter router;

  /// Entries for the main navigation bar, from every module, in order.
  final List<NavDestination> destinations;

  /// Registers, starts and routes [modules].
  ///
  /// [shell], when given, wraps every module's screens (for example in a
  /// navigation bar). It is the app's, not any module's.
  ///
  /// [storage] is where modules keep data between launches; each module
  /// sees only its own scope of it. Tests leave it out and get memory.
  ///
  /// [flags] holds the values of feature flags for this run. Every flag a
  /// module declares must start with the module's name; a flag declared by
  /// a module it does not belong to, or declared twice, fails at startup.
  ///
  /// Throws [StateError] when two modules share a name or claim the same
  /// top-level route, because both are wiring mistakes that should fail
  /// at startup, not later in production.
  static Future<ModuleHost> start({
    required List<FeatureModule> modules,
    Clock clock = const SystemClock(),
    KeyValueStore? storage,
    FlagValues flags = const FlagValues(),
    String initialLocation = '/',
    ShellRouteBuilder? shell,
  }) async {
    final di = GetIt.asNewInstance();
    di
      ..registerSingleton<EventBus>(EventBus(onSubscriberError: _report))
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<KeyValueStore>(storage ?? InMemoryKeyValueStore())
      ..registerSingleton<FeatureFlags>(flags);
    _checkFlags(modules);

    final names = <String>{};
    for (final module in modules) {
      if (!names.add(module.name)) {
        throw StateError('Module "${module.name}" is registered twice');
      }
      module.register(di);
    }

    for (final module in modules) {
      await module.start(di);
    }

    final routes = <RouteBase>[];
    final owners = <String, String>{};
    for (final module in modules) {
      for (final route in module.routes(di)) {
        if (route is GoRoute) {
          final owner = owners[route.path];
          if (owner != null) {
            throw StateError('Route "${route.path}" is claimed by both '
                '"$owner" and "${module.name}"');
          }
          owners[route.path] = module.name;
        }
        routes.add(route);
      }
    }

    final router = GoRouter(
      initialLocation: initialLocation,
      // The app may wrap every module's screens in one frame, such as a
      // navigation bar. Inside a ShellRoute it sits within the navigator.
      routes:
          shell == null ? routes : [ShellRoute(builder: shell, routes: routes)],
      redirect: (context, state) async {
        for (final module in modules) {
          final target = await module.redirect(di, state);
          if (target != null && target != state.uri.toString()) {
            return target;
          }
        }
        return null;
      },
    );
    final destinations = [
      for (final module in modules) ...module.destinations(di),
    ]..sort((a, b) => a.order.compareTo(b.order));

    return ModuleHost._(di, List.unmodifiable(modules), router,
        List.unmodifiable(destinations));
  }

  /// Stops modules in reverse order and releases shared resources.
  Future<void> stop() async {
    for (final module in modules.reversed) {
      await module.stop();
    }
    router.dispose();
    di<EventBus>().close();
    await di.reset();
  }

  /// Each module may only declare flags in its own namespace, and no two
  /// flags may share a name: both are wiring mistakes.
  static void _checkFlags(List<FeatureModule> modules) {
    final seen = <String>{};
    for (final module in modules) {
      for (final flag in module.flags) {
        if (flag.owner != module.name) {
          throw StateError('Module "${module.name}" declares flag '
              '"${flag.name}"; its flags must start with "${module.name}."');
        }
        if (!seen.add(flag.name)) {
          throw StateError('Flag "${flag.name}" is declared twice');
        }
      }
    }
  }

  static void _report(DomainEvent event, Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'event_bus',
      context: ErrorDescription('while handling ${event.runtimeType}'),
    ));
  }
}
