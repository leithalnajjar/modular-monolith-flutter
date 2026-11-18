import 'package:material_ui/material_ui.dart';

import '../app_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: FilledButton(
          onPressed: () => state.login('demo@shop.dev', 'shop123'),
          child: const Text('Sign in as demo'),
        ),
      ),
    );
  }
}
