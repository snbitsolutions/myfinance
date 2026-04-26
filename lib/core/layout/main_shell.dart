import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'responsive.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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

    if (isExpanded) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (index == 0) context.go('/home');
                if (index == 1) context.go('/savings');
                if (index == 2) context.go('/transactions');
                if (index == 3) context.go('/profile');
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
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings_rounded),
                  label: Text('Savings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz_rounded),
                  label: Text('Transactions'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color:
                theme.bottomNavigationBarTheme.backgroundColor ??
                theme.colorScheme.surface,
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
                label: 'Savings',
                selected: currentIndex == 1,
                onTap: () => context.go('/savings'),
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  context.go('/savings/types');
                },
              ),
              _ShellNavItem(
                icon: Icons.swap_horiz,
                label: 'Transactions',
                selected: currentIndex == 2,
                onTap: () => context.go('/transactions'),
              ),
              _ShellNavItem(
                icon: Icons.person,
                label: 'Profile',
                selected: currentIndex == 3,
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
    if (location.startsWith('/transactions')) return 2;
    if (location.startsWith('/profile')) return 3;
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
