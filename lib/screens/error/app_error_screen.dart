import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppErrorScreen extends StatelessWidget {
  final String? message;

  const AppErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Something went wrong')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 68,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'We could not open that page.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message ?? 'Please try again, or return to the dashboard.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Go to Dashboard'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Go to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
