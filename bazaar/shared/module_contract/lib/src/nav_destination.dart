import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// An entry a module adds to the app's main navigation bar.
///
/// The app draws the bar; modules only say what should be on it. That is
/// how the cart can show its item count in the app's navigation without
/// the app knowing what a cart is.
final class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.location,
    this.badge,
    this.order = 100,
  });

  final String label;
  final IconData icon;

  /// Where tapping the entry goes. Also used to highlight the entry while
  /// the user is anywhere under this location.
  final String location;

  /// A number to show on the icon, such as items in the cart. Zero hides it.
  final ValueListenable<int>? badge;

  /// Lower comes first.
  final int order;
}
