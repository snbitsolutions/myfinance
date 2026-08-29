import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_providers.dart';
import 'responsive.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // Track previous online state to only show the "back online" flash once.
  static const _savingsHintSeenKey = 'hint_long_press_savings_seen';

  @override
  void initState() {
    super.initState();
    _showSavingsLongPressHintIfNeeded();
  }

  Future<void> _showSavingsLongPressHintIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final seenHint = prefs.getBool(_savingsHintSeenKey) ?? false;
    if (seenHint || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip: Long-press Savings tab to choose savings type.'),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    await prefs.setBool(_savingsHintSeenKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndex(context);
    final theme = Theme.of(context);
    final isExpanded = Responsive.isExpanded(context);

    // Connectivity banner
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOnline = connectivityAsync.valueOrNull ?? true;

    // When connectivity is restored, show a brief snackbar.
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final wasOnline = prev?.valueOrNull;
      final nowOnline = next.valueOrNull;
      if (wasOnline == false && nowOnline == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Back online'),
              ],
            ),
            backgroundColor: theme.colorScheme.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    if (isExpanded) {
      return Scaffold(
        body: Column(
          children: [
            _OfflineBanner(isOnline: isOnline),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) {
                      if (index == 0) context.go('/home');
                      if (index == 1) context.go('/savings');
                      if (index == 2) context.go('/payment');
                      if (index == 3) context.go('/transactions');
                      if (index == 4) context.go('/profile');
                    },
                    extended: Responsive.isLarge(context),
                    useIndicator: true,
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: FloatingActionButton.small(
                        onPressed: () => context.go('/home'),
                        child: const Icon(Icons.home_rounded),
                      ),
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IconButton(
                        tooltip: 'Savings types',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.go('/savings/types');
                        },
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.grid_view_outlined),
                        selectedIcon: Icon(Icons.grid_view_outlined),
                        label: Text('Products'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.swap_horiz_outlined),
                        selectedIcon: Icon(Icons.swap_horiz_rounded),
                        label: Text('Payments'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long_rounded),
                        label: Text('Activity'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.more_horiz),
                        selectedIcon: Icon(Icons.more_horiz),
                        label: Text('More'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _OfflineBanner(isOnline: isOnline),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              _ShellNavItem(
                icon: Icons.home,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
              _ShellNavItem(
                icon: Icons.savings,
                label: 'Products',
                selected: currentIndex == 1,
                onTap: () => context.go('/savings'),
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  context.go('/savings/types');
                },
              ),
              _ShellNavItem(
                icon: Icons.swap_horiz,
                label: 'Payments',
                selected: currentIndex == 2,
                onTap: () => context.go('/payment'),
              ),
              _ShellNavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Activity',
                selected: currentIndex == 3,
                onTap: () => context.go('/transactions'),
              ),
              _ShellNavItem(
                icon: Icons.more_horiz,
                label: 'More',
                selected: currentIndex == 4,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/savings')) return 1;
    if (location.startsWith('/payment')) return 2;
    if (location.startsWith('/transactions')) return 3;
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/notifications')) {
      return 4;
    }
    return 0;
  }
}

class _ShellNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ShellNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor =
        theme.bottomNavigationBarTheme.selectedItemColor ??
        theme.colorScheme.primary;
    final unselectedColor =
        theme.bottomNavigationBarTheme.unselectedItemColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final tint = selected ? selectedColor : unselectedColor;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: tint, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tint,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 18 : 0,
                  height: 4,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool isOnline;
  const _OfflineBanner({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: isOnline
          ? const SizedBox.shrink()
          : Material(
              color: const Color(0xFFC62828),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
