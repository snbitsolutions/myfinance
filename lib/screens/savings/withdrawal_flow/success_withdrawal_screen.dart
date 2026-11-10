import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_card.dart';
import '../../../core/color_ext.dart';
import 'withdrawal_model.dart';

class SuccessWithdrawalScreen extends StatelessWidget {
  final WithdrawalData data;

  const SuccessWithdrawalScreen({super.key, required this.data});

  List<Widget> _generateDecorativeDots() {
    final colors = [
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF9C4),
      const Color(0xFFE0F2F1),
      const Color(0xFFFFF9C4),
      const Color(0xFFE8F5E9),
    ];

    final positions = [
      (dx: -40.0, dy: -60.0),
      (dx: 60.0, dy: -50.0),
      (dx: -70.0, dy: 20.0),
      (dx: 80.0, dy: 30.0),
      (dx: 0.0, dy: 80.0),
    ];

    return List.generate(
      colors.length,
      (i) => Positioned(
        left: 60 + positions[i].dx,
        top: 60 + positions[i].dy,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = data.isPending;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Dark green header at the very top
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF075D21), Color(0xFF08752B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  isPending
                      ? 'Withdrawal Pending'
                      : 'Provider reported completion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Success Icon with decorative dots
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ..._generateDecorativeDots(),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacitySafe(
                                0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPending
                              ? Icons.hourglass_top_rounded
                              : Icons.check_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    isPending
                        ? 'Withdrawal Pending'
                        : 'Provider reported completion',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Message
                  Text(
                    isPending
                        ? 'Your withdrawal request was accepted and is awaiting confirmation.'
                        : 'The provider reported that the withdrawal completed.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Amount
                  Text(
                    'GH₵ ${data.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPending ? 'Withdrawal Requested' : 'Amount Withdrawn',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Transaction Details
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow('From Account', data.fromAccount, theme),
                        _DetailRow('To', data.method, theme),
                        _DetailRow('Phone Number', data.phoneNumber, theme),
                        _DetailRow(
                          isPending
                              ? 'Request Reference'
                              : 'Provider Reference',
                          data.reference ?? 'Unavailable',
                          theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // New Balance
                  AppCard(
                    backgroundColor: const Color(0xFFF0F8EF),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPending
                                    ? 'Balance will update after confirmation'
                                    : 'New Available Balance',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPending || data.newBalance == null
                                    ? 'Unavailable'
                                    : 'GH₵ ${data.newBalance!.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () =>
                          context.push('/withdrawal/receipt', extra: data),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Receipt'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => context.go('/savings'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.check_rounded, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
