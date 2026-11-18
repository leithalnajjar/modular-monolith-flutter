// apps/bazaar_app/lib/shell.dart
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:module_contract/module_contract.dart';

/// The frame around every screen: the main navigation bar.
///
/// The shell knows nothing about shops, carts or accounts. It draws one
/// entry per [NavDestination] that the modules contributed, highlights the
/// one the user is in, and shows badges when a module provides a count.
class BazaarShell extends StatelessWidget {
  const BazaarShell({
    super.key,
    required this.destinations,
    required this.location,
    required this.child,
  });

  final List<NavDestination> destinations;

  /// The current path, used to highlight the right entry.
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (destinations.length < 2) return child; // a bar needs two entries

    final index = destinations.indexWhere(
      (d) => location.startsWith(d.location),
    );
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(destinations[i].location),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              label: d.label,
              icon: _BadgedIcon(icon: d.icon, badge: d.badge),
            ),
        ],
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, this.badge});

  final IconData icon;
  final ValueListenable<int>? badge;

  @override
  Widget build(BuildContext context) {
    final count = badge;
    if (count == null) return Icon(icon);
    return ValueListenableBuilder<int>(
      valueListenable: count,
      builder: (context, value, _) => Badge(
        isLabelVisible: value > 0,
        label: Text('$value'),
        child: Icon(icon),
      ),
    );
  }
}
