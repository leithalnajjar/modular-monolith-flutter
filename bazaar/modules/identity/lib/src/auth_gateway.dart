import 'package:core/core.dart';
import 'package:identity_api/identity_api.dart';

/// The port between identity and whatever really checks credentials: your
/// own backend, Firebase Auth, an OAuth provider.
///
/// Identity's rules (validate input, publish events, keep the session)
/// do not change when the backend does. Only the adapter does.
abstract interface class AuthGateway {
  /// Returns the user for these credentials, [Unauthorized] when they are
  /// wrong, or [Unavailable] when the backend cannot be reached.
  Future<Result<SignedInUser>> verify(String email, String password);
}

/// An adapter with one built-in account, for demos and tests.
///
/// Never ship credentials in an app. A real adapter sends them over HTTPS
/// to a server and keeps only the token it gets back, in secure storage.
final class DemoAuthGateway implements AuthGateway {
  const DemoAuthGateway();

  static const email = 'demo@bazaar.dev';
  static const password = 'bazaar123';

  @override
  Future<Result<SignedInUser>> verify(String email, String password) async =>
      email == DemoAuthGateway.email && password == DemoAuthGateway.password
          ? const Result.ok(
              SignedInUser(id: UserId('u-demo'), displayName: 'Demo Shopper'))
          : const Result.err(Unauthorized('Wrong email or password'));
}
