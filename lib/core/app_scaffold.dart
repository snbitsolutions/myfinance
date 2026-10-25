import 'dart:async';

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
  final String? backRoute;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showBack = true,
    this.backRoute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = context.canPop();

    Future<void> handleBackNavigation() async {
      if (!context.mounted) return;

      if (backRoute != null) {
        context.go(backRoute!);
        return;
      }

      if (context.canPop()) {
        context.pop();
        return;
      }

      await NavigationHistory.instance.goBack(context);
    }

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !context.mounted) {
          return;
        }

        unawaited(handleBackNavigation());
      },
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: showBack ? 56 : null,
          leading: showBack
              ? IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 56,
                    height: 56,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  tooltip: 'Back',
                  onPressed: handleBackNavigation,
                )
              : null,
          title: Text(
            title,
            style:
                theme.appBarTheme.titleTextStyle ??
                theme.textTheme.titleMedium?.copyWith(
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
