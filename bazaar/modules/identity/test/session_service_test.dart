import 'package:core/core.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity/identity.dart';
import 'package:identity/src/session_service.dart';
import 'package:identity_api/identity_api.dart';

void main() {
  final start = DateTime.utc(2027, 3, 1, 9);
  late EventBus bus;
  late FixedClock clock;
  late SessionService session;
  late List<DomainEvent> published;

  setUp(() {
    bus = EventBus();
    clock = FixedClock(start);
    session = SessionService(const DemoAuthGateway(), bus, clock);
    published = [];
    bus.on<DomainEvent>(published.add);
  });

  test('malformed input is a rule violation, checked before the backend',
      () async {
    final result = await session.signIn('not-an-email', 'x');
    expect((result as Err<SignedInUser>).failure, isA<RuleViolation>());
    expect(published, isEmpty);
  });

  test('wrong credentials are Unauthorized and change nothing', () async {
    final result = await session.signIn(DemoAuthGateway.email, 'wrong');
    expect((result as Err<SignedInUser>).failure, isA<Unauthorized>());
    expect(session.isSignedIn, isFalse);
    expect(published, isEmpty);
  });

  test('signing in publishes UserSignedIn with the clock time', () async {
    final result =
        await session.signIn(DemoAuthGateway.email, DemoAuthGateway.password);

    expect(result.valueOrNull?.displayName, 'Demo Shopper');
    expect(session.currentUser?.id, const UserId('u-demo'));
    final event = published.single as UserSignedIn;
    expect(event.userId, const UserId('u-demo'));
    expect(event.occurredAt, start);
  });

  test('signing out publishes UserSignedOut, once', () async {
    await session.signIn(DemoAuthGateway.email, DemoAuthGateway.password);
    clock.advance(const Duration(minutes: 30));

    await session.signOut();
    await session.signOut(); // already signed out: nothing happens

    expect(session.isSignedIn, isFalse);
    final signedOut = published.whereType<UserSignedOut>().single;
    expect(signedOut.occurredAt, start.add(const Duration(minutes: 30)));
  });

  test('the guard redirects only when signed out, remembering the target',
      () async {
    final target = Uri.parse('/checkout?step=2');
    expect(signInRedirect(session, target),
        '/sign-in?from=%2Fcheckout%3Fstep%3D2');

    await session.signIn(DemoAuthGateway.email, DemoAuthGateway.password);
    expect(signInRedirect(session, target), isNull);
  });
}
