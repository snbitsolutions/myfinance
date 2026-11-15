import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({
    super.key,
    required this.accountNumber,
    required this.phoneNumber,
  });

  final String accountNumber;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppScaffold(
      title: 'Account Created',
      showBack: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 58,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Registration successful',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your phone number has been verified and your account is ready.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Account number',
                        value: accountNumber.isEmpty
                            ? 'Available from your welcome SMS'
                            : accountNumber,
                      ),
                      const Divider(height: 24),
                      _DetailRow(label: 'Phone number', value: phoneNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Continue to dashboard'),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
