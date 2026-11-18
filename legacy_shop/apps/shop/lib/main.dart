import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() => runApp(ShopApp(state: AppState()));

class ShopApp extends StatelessWidget {
  const ShopApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListenableBuilder(
        listenable: state,
        builder: (context, _) => state.currentUser == null
            ? LoginScreen(state: state)
            : HomeScreen(state: state),
      ),
    );
  }
}
