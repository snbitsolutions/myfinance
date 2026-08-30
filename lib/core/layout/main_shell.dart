import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _BottomNavItem {
  final String label;
  final IconData icon;
  final String route;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const List<_BottomNavItem> _items = [
    _BottomNavItem(label: 'Home', icon: Icons.home_rounded, route: '/home'),
    _BottomNavItem(
      label: 'Product',
      icon: Icons.grid_view_rounded,
      route: '/products',
    ),
    _BottomNavItem(
      label: 'Pay',
      icon: Icons.payment_rounded,
      route: '/pay',
    ),
    _BottomNavItem(
      label: 'Activity',
      icon: Icons.bar_chart_rounded,
      route: '/activity',
    ),
    _BottomNavItem(
      label: 'More',
      icon: Icons.menu_rounded,
      route: '/more',
    ),
  ];

  int _resolveIndex(String location) {
    final normalizedLocation = location.split('?').first;
    final index = _items.indexWhere((item) => item.route == normalizedLocation);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final currentIndex = _resolveIndex(currentLocation);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: const Color(0xFF7B8A7F),
              selectedFontSize: 11,
              unselectedFontSize: 10,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 0,
              onTap: (index) {
                final destination = _items[index].route;
                if (currentLocation != destination) {
                  context.go(destination);
                }
              },
              items: _items
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.icon, size: 24),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
