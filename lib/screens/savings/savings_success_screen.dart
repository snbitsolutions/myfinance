import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import 'savings_model.dart';

class SavingsSuccessScreen extends StatefulWidget {
  final Savings savings;

  const SavingsSuccessScreen({super.key, required this.savings});

  @override
  State<SavingsSuccessScreen> createState() => _SavingsSuccessScreenState();
}

class _SavingsSuccessScreenState extends State<SavingsSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Goal Created',
      showBack: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Animated Success Hero Card
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacitySafe(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacitySafe(0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacitySafe(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Savings Goal Created!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You\'re on your way to financial freedom.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacitySafe(0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Goal Summary Details
            AppCard(
              backgroundColor: theme.colorScheme.primaryContainer
                  .withOpacitySafe(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.savings_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Goal Summary',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _GoalDetail(
                    label: 'Goal Name',
                    value: widget.savings.title,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  const SizedBox(height: 12),
                  _GoalDetail(
                    label: 'Target Amount',
                    value: 'GH₵${widget.savings.target.toStringAsFixed(2)}',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  const SizedBox(height: 12),
                  _GoalDetail(
                    label: 'Savings Type',
                    value: widget.savings.type.label,
                    theme: theme,
                  ),
                  if (widget.savings.type == SavingsType.fixedDeposit) ...[
                    const SizedBox(height: 12),
                    Divider(
                      color: theme.colorScheme.outline.withOpacitySafe(0.2),
                    ),
                    const SizedBox(height: 12),
                    _GoalDetail(
                      label: 'Interest Rate',
                      value:
                          widget.savings.interestRate == null
                              ? 'Unavailable'
                              : '${widget.savings.interestRate!.toStringAsFixed(1)}% p.a.',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: theme.colorScheme.outline.withOpacitySafe(0.2),
                    ),
                    const SizedBox(height: 12),
                    _GoalDetail(
                      label: 'Maturity Date',
                      value: widget.savings.maturityDate != null
                          ? '${widget.savings.maturityDate!.day}/${widget.savings.maturityDate!.month}/${widget.savings.maturityDate!.year}'
                          : '—',
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Primary Action: View Goal Details
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => context.go(
                  '/savings/${widget.savings.id}',
                  extra: widget.savings,
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('View Goal'),
                style: FilledButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary Action: Create Another Goal
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate back to type picker
                  context.go('/savings/types');
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Another Goal'),
              ),
            ),

            const SizedBox(height: 12),

            // Tertiary Action: Back to Savings
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/savings', extra: widget.savings),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Savings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDetail extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _GoalDetail({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
