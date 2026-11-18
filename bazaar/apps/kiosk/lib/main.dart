// apps/kiosk/lib/main.dart
import 'package:material_ui/material_ui.dart';

import 'kiosk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KioskApp(host: await startKiosk()));
}
