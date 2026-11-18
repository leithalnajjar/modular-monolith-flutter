import 'session.dart';

abstract final class IdentityRoutes {
  static const signIn = '/sign-in';
  static const account = '/account';

  /// The sign-in location that returns the user to [from] afterwards.
  static String signInThen(String from) =>
      Uri(path: signIn, queryParameters: {'from': from}).toString();
}

/// The guard every module uses for routes that need a signed-in user.
///
/// Returns the sign-in location (remembering [location]) when nobody is
/// signed in, or `null` to let navigation continue. Pure Dart, so contract
/// packages and tests can use it without Flutter. Modules call it from a
/// route's `redirect`.
String? signInRedirect(Session session, Uri location) =>
    session.isSignedIn ? null : IdentityRoutes.signInThen(location.toString());
