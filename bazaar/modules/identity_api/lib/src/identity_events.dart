import 'package:event_bus/event_bus.dart';

import 'user_id.dart';

/// A user has signed in. Published by the identity module.
final class UserSignedIn extends DomainEvent {
  const UserSignedIn(this.userId, {required DateTime at}) : super(at);
  final UserId userId;
}

/// A user has signed out. Every module that keeps per-user data clears it
/// when it sees this event; identity does not need to know who they are.
final class UserSignedOut extends DomainEvent {
  const UserSignedOut(this.userId, {required DateTime at}) : super(at);
  final UserId userId;
}
