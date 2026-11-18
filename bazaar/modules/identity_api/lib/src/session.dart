import 'package:core/core.dart';

import 'user_id.dart';

/// The signed-in user, as other modules see them.
final class SignedInUser {
  const SignedInUser({required this.id, required this.displayName});
  final UserId id;
  final String displayName;
}

/// Who is signed in right now. Any module may read it.
abstract interface class Session {
  /// The current user, or `null` when nobody is signed in.
  SignedInUser? get currentUser;

  bool get isSignedIn;

  /// Emits the new user (or `null`) after every sign-in and sign-out.
  Stream<SignedInUser?> get changes;
}

/// Signing in and out. Only identity's own screens use this in Bazaar,
/// but it is public so that, for example, a settings module could offer a
/// "sign out" button.
abstract interface class SessionCommands {
  /// Returns the signed-in user, or [RuleViolation] for malformed input,
  /// or [Unauthorized] for wrong credentials.
  Future<Result<SignedInUser>> signIn(String email, String password);

  /// Signs out. Does nothing if nobody is signed in.
  Future<void> signOut();
}
