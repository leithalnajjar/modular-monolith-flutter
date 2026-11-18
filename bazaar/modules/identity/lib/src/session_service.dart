import 'dart:async';

import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:identity_api/identity_api.dart';

import 'auth_gateway.dart';

/// Identity's session: who is signed in, and the rules for changing that.
final class SessionService implements Session, SessionCommands {
  SessionService(this._gateway, this._bus, this._clock);

  final AuthGateway _gateway;
  final EventBus _bus;
  final Clock _clock;
  final _changes = StreamController<SignedInUser?>.broadcast();

  SignedInUser? _user;

  @override
  SignedInUser? get currentUser => _user;

  @override
  bool get isSignedIn => _user != null;

  @override
  Stream<SignedInUser?> get changes => _changes.stream;

  @override
  Future<Result<SignedInUser>> signIn(String email, String password) async {
    final trimmed = email.trim();
    if (!trimmed.contains('@') || password.isEmpty) {
      return const Result.err(
          RuleViolation('Enter your email address and password'));
    }
    final result = await _gateway.verify(trimmed, password);
    if (result case Ok(:final value)) {
      if (_user != null && _user!.id != value.id) await signOut();
      _user = value;
      _changes.add(value);
      // Await: when signIn returns, every module has reacted.
      await _bus.publish(UserSignedIn(value.id, at: _clock.now()));
    }
    return result;
  }

  @override
  Future<void> signOut() async {
    final user = _user;
    if (user == null) return;
    _user = null;
    _changes.add(null);
    await _bus.publish(UserSignedOut(user.id, at: _clock.now()));
  }

  Future<void> dispose() => _changes.close();
}
