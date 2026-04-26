import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/navigation_history.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showBack;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = context.canPop();
    Future<void> handleBackNavigation() async {
      // Prefer popping the Navigator; if nothing to pop, go to tracked previous page.
      if (!context.mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        await NavigationHistory.instance.goBack(context);
      }
    }

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !context.mounted) {
          return;
        }
        NavigationHistory.instance.goBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: handleBackNavigation,
                )
              : null,
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          centerTitle: true,
          elevation: 0.5,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.primary,
          actions: actions,
        ),
        body: child,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
