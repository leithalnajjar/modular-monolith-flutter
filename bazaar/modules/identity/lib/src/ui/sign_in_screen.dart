import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:identity_api/identity_api.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';

/// Signs the user in, then returns them to where they were going.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.commands, this.from});

  final SessionCommands commands;

  /// The location to continue to after signing in (from a route guard).
  final String? from;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.commands.signIn(_email.text, _password.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.go(widget.from ?? IdentityRoutes.account);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('email'),
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              key: const Key('password'),
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: Spacing.m),
            if (_error != null)
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: Spacing.m),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
