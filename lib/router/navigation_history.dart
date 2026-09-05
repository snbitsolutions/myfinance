import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationHistory {
  NavigationHistory._();

  static final NavigationHistory instance = NavigationHistory._();

  final List<String> _history = <String>[];
  bool _isAttached = false;

  void attach(GoRouter router) {
    if (_isAttached) return;
    _isAttached = true;

    void syncCurrentLocation() {
      final current = _currentLocation(router);
      if (current == null || current.isEmpty) return;
      if (_history.isEmpty || _history.last != current) {
        _history.add(current);
      }

      // Keep memory bounded.
      if (_history.length > 100) {
        _history.removeRange(0, _history.length - 100);
      }
    }

    syncCurrentLocation();
    router.routeInformationProvider.addListener(syncCurrentLocation);
  }

  Future<void> goBack(
    BuildContext context, {
    String fallbackRoute = '/home',
  }) async {
    if (!context.mounted) return;

    if (context.canPop()) {
      context.pop();
      return;
    }

    final router = GoRouter.of(context);
    final current = _currentLocation(router);

    if (current != null && _history.isNotEmpty && _history.last == current) {
      _history.removeLast();
    }

    if (_history.isNotEmpty) {
      final previous = _history.last;
      if (previous != current) {
        context.go(previous);
        return;
      }
    }

    final fallbackFromPath = _fallbackRouteForPath(current);
    if (fallbackFromPath != null) {
      context.go(fallbackFromPath);
      return;
    }

    context.go(fallbackRoute);
  }

  String? _fallbackRouteForPath(String? current) {
    if (current == null || current.isEmpty) return null;

    final path = current.split('?').first.split('#').first;

    if (path == '/loan-detail' || path.startsWith('/loans/')) {
      return '/loans';
    }

    if (path == '/loan-status' ||
        path == '/apply-loan' ||
        path == '/repayment') {
      return '/loans';
    }

    if (path.startsWith('/shares/')) {
      return '/shares';
    }

    if (path.startsWith('/savings/')) {
      return '/savings';
    }

    if (path.startsWith('/payment')) {
      return '/home';
    }

    return null;
  }

  String? _currentLocation(GoRouter router) {
    final uri = router.routeInformationProvider.value.uri;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    final fragment = uri.fragment.isNotEmpty ? '#${uri.fragment}' : '';
    return '${uri.path}$query$fragment';
  }
}
