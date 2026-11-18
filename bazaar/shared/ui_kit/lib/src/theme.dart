import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The one theme of the app. Modules never create their own ThemeData.
///
/// [seed] is the brand colour every other colour is generated from. Apps
/// built from the same modules for another brand (Chapter 23) pass their
/// own; everything else about the design stays shared.
ThemeData bazaarTheme({
  Brightness brightness = Brightness.light,
  Color seed = BazaarColors.brand,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.button),
  );
  return ThemeData(
    colorScheme: scheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: rounded, minimumSize: const Size(0, 44)),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: Spacing.m),
    ),
  );
}
