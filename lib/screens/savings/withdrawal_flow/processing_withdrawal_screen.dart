import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import 'withdrawal_model.dart';

class ProcessingWithdrawalScreen extends StatefulWidget {
  final WithdrawalData data;

  const ProcessingWithdrawalScreen({super.key, required this.data});

  @override
  State<ProcessingWithdrawalScreen> createState() => _ProcessingWithdrawalScreenState();
}

class _ProcessingWithdrawalScreenState extends State<ProcessingWithdrawalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Simulate processing delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final updatedData = widget.data.copyWith(
        reference: 'ADEPA-${DateTime.now().millisecondsSinceEpoch}',
        processedAt: DateTime.now(),
        newBalance: 44000,
      );
      context.push('/withdrawal/success', extra: updatedData);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Processing',
      showBack: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading spinner
          SizedBox(
            width: 120,
            height: 120,
            child: RotationTransition(
              turns: _controller,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacitySafe(0.2),
                    width: 4,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacitySafe(0.5),
                        width: 4,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 4,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Processing message
          Text(
            'Processing your withdrawal',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Please wait while we securely process your transaction.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Dots animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = (_controller.value * 3 - i) % 3;
                  final opacity = (1 - offset).clamp(0.0, 1.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
