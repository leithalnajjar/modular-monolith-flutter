import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:module_contract/module_contract.dart';

import 'inbox.dart';
import 'ui/inbox_screen.dart';

/// The most decoupled module in Bazaar: it publishes nothing, exposes no
/// contract, and could be deleted without any other module noticing.
final class NotificationsModule extends FeatureModule {
  NotificationsModule();

  static const inboxLocation = '/inbox';

  Inbox? _inbox;

  @override
  String get name => 'notifications';

  @override
  void register(GetIt di) {
    di.registerLazySingleton<Inbox>(() => Inbox(di<Session>()));
  }

  @override
  Future<void> start(GetIt di) async {
    _inbox = di<Inbox>()..listenTo(di<EventBus>());
  }

  @override
  List<NavDestination> destinations(GetIt di) => [
        NavDestination(
          label: 'Inbox',
          icon: Icons.notifications_none,
          location: inboxLocation,
          badge: di<Inbox>().unread,
          order: 40,
        ),
      ];

  @override
  List<RouteBase> routes(GetIt di) => [
        GoRoute(
          path: inboxLocation,
          builder: (_, __) => InboxScreen(inbox: di<Inbox>()),
        ),
      ];

  @override
  Future<void> stop() async => _inbox?.stop();
}
