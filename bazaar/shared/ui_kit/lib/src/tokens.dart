import 'package:material_ui/material_ui.dart';

/// The design decisions, named. Modules use these names, never raw numbers
/// or hex codes, so a design change is one edit here.
abstract final class BazaarColors {
  /// The brand colour every Material colour scheme is generated from.
  static const brand = Color(0xFF2E7D6B);
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFB7791F);
}

abstract final class Spacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

abstract final class Radii {
  static const card = 12.0;
  static const button = 10.0;
}
