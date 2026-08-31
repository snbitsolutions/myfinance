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
    final isStandaloneSavingsView =
        currentLocation == '/savings' || currentLocation.startsWith('/savings/');
    final isStandalonePaymentView =
        currentLocation == '/payment' || currentLocation.startsWith('/payment/');

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: isStandaloneSavingsView || isStandalonePaymentView
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: BottomNavigationBar(
                    currentIndex: currentIndex,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    selectedItemColor: const Color(0xFF0F8E5D),
                    unselectedItemColor: const Color(0xFF7B8A7F),
                    selectedFontSize: 11,
                    unselectedFontSize: 10,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    elevation: 0,
                    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    onTap: (index) {
                      final destination = _items[index].route;
                      if (currentLocation != destination) {
                        context.go(destination);
                      }
                    },
                    items: _items
                        .map(
                          (item) => BottomNavigationBarItem(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: currentLocation == item.route
                                    ? const Color(0xFFEAF5EE)
                                    : Colors.transparent,
                              ),
                              child: Icon(item.icon, size: 22),
                            ),
                            activeIcon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xFFEAF5EE),
                              ),
                              child: Icon(item.icon, size: 22, color: const Color(0xFF0F8E5D)),
                            ),
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
