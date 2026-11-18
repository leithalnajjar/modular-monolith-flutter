// apps/bazaar_app/lib/main.dart
import 'package:material_ui/material_ui.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:module_contract/module_contract.dart';

import 'config.dart';
import 'modules.dart';
import 'preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Values from --dart-define-from-file=config/<environment>.json. A broken
  // configuration stops here, with a message, before any module starts.
  final config = BazaarConfig.fromEnvironment();
  runApp(
    BazaarApp(
      host: await startBazaar(config: config, storage: PreferencesStore()),
    ),
  );
}

/// The app. It knows nothing about any feature: it shows the router that
/// the [ModuleHost] built from the modules' routes and the app's shell.
class BazaarApp extends StatelessWidget {
  const BazaarApp({super.key, required this.host});

  final ModuleHost host;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bazaar',
      theme: bazaarTheme(),
      darkTheme: bazaarTheme(brightness: Brightness.dark),
      routerConfig: host.router,
    );
  }
}
