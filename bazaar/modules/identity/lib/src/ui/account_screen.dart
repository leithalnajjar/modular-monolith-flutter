import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// The signed-in user's account page. Only reachable when signed in,
/// thanks to the route guard.
class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    required this.session,
    required this.commands,
  });

  final Session session;
  final SessionCommands commands;

  @override
  Widget build(BuildContext context) {
    final user = session.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in as ${user?.displayName ?? '...'}'),
            const SizedBox(height: Spacing.l),
            OutlinedButton(
              onPressed: () async {
                await commands.signOut();
                if (context.mounted) context.go(IdentityRoutes.signIn);
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
