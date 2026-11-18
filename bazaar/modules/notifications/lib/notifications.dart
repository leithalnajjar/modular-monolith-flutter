/// The notifications module. Only the app imports this library.
///
/// There is no `notifications_api` package: no other module needs to call
/// notifications, so there is no contract to publish.
library;

export 'src/notifications_module.dart' show NotificationsModule;
