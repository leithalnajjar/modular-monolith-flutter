import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:module_contract/module_contract.dart';

import 'auth_gateway.dart';
import 'session_service.dart';
import 'ui/account_screen.dart';
import 'ui/sign_in_screen.dart';

final class IdentityModule extends FeatureModule {
  /// [gateway] is the adapter to the real authentication backend. The app
  /// chooses it; identity's rules do not change.
  const IdentityModule({this.gateway = const DemoAuthGateway()});

  final AuthGateway gateway;

  @override
  String get name => 'identity';

  @override
  void register(GetIt di) {
    di
      ..registerLazySingleton<SessionService>(
        () => SessionService(gateway, di<EventBus>(), di<Clock>()),
        dispose: (service) => service.dispose(),
      )
      ..registerLazySingleton<Session>(() => di<SessionService>())
      ..registerLazySingleton<SessionCommands>(() => di<SessionService>());
  }

  @override
  List<NavDestination> destinations(GetIt di) => const [
        NavDestination(
          label: 'Account',
          icon: Icons.person_outline,
          location: IdentityRoutes.account,
          order: 90,
        ),
      ];

  @override
  List<RouteBase> routes(GetIt di) => [
        GoRoute(
          path: IdentityRoutes.signIn,
          builder: (context, state) => SignInScreen(
            commands: di<SessionCommands>(),
            from: state.uri.queryParameters['from'],
          ),
        ),
        GoRoute(
          path: IdentityRoutes.account,
          // The same guard every module uses for its protected routes.
          redirect: (context, state) =>
              signInRedirect(di<Session>(), state.uri),
          builder: (context, state) => AccountScreen(
            session: di<Session>(),
            commands: di<SessionCommands>(),
          ),
        ),
      ];
}
