import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:module_contract/module_contract.dart';

/// A module that records every lifecycle call into a shared log.
final class _Recorder extends FeatureModule {
  _Recorder(this.name, this.log, {this.path});

  @override
  final String name;
  final List<String> log;
  final String? path;

  @override
  void register(GetIt di) => log.add('register $name');

  @override
  Future<void> start(GetIt di) async {
    // Shared services are available to every module.
    di<EventBus>();
    di<Clock>();
    log.add('start $name');
  }

  @override
  List<RouteBase> routes(GetIt di) => [
        if (path != null)
          GoRoute(path: path!, builder: (_, __) => const SizedBox()),
      ];

  @override
  Future<void> stop() async => log.add('stop $name');
}

/// A module that declares the flags it is given.
final class _Flagged extends FeatureModule {
  _Flagged(this.name, this.flags);

  @override
  final String name;

  @override
  final List<Flag> flags;

  @override
  void register(GetIt di) {}
}

const _express = Flag('checkout.express', description: 'One-tap checkout.');

void main() {
  test('registers all modules before starting any, stops in reverse',
      () async {
    final log = <String>[];
    final host = await ModuleHost.start(modules: [
      _Recorder('a', log, path: '/a'),
      _Recorder('b', log, path: '/b'),
    ]);
    await host.stop();

    expect(log, [
      'register a',
      'register b',
      'start a',
      'start b',
      'stop b',
      'stop a',
    ]);
  });

  test('two modules with the same name fail at startup', () async {
    final log = <String>[];
    expect(
      () => ModuleHost.start(
          modules: [_Recorder('cart', log), _Recorder('cart', log)]),
      throwsA(isA<StateError>()),
    );
  });

  test('two modules claiming the same route fail at startup', () async {
    final log = <String>[];
    await expectLater(
      ModuleHost.start(modules: [
        _Recorder('catalog', log, path: '/products'),
        _Recorder('promotions', log, path: '/products'),
      ]),
      throwsA(isA<StateError>().having((e) => e.message, 'message',
          contains('claimed by both "catalog" and "promotions"'))),
    );
  });

  test('each host has its own container', () async {
    final first = await ModuleHost.start(modules: const []);
    final second = await ModuleHost.start(modules: const []);
    expect(identical(first.di<EventBus>(), second.di<EventBus>()), isFalse);
    await first.stop();
    await second.stop();
  });

  test('modules read flag values set by the app', () async {
    final host = await ModuleHost.start(
      modules: [_Flagged('checkout', [_express])],
      flags: const FlagValues({'checkout.express': true}),
    );
    addTearDown(host.stop);
    expect(host.di<FeatureFlags>().isOn(_express), isTrue);
  });

  test('a module may only declare flags in its own namespace', () {
    expect(
      () => ModuleHost.start(modules: [_Flagged('cart', [_express])]),
      throwsA(isA<StateError>().having((e) => e.message, 'message',
          contains('its flags must start with "cart."'))),
    );
  });
}
