import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/logger.dart';
import 'withdrawal_model.dart';

class ProcessingWithdrawalScreen extends ConsumerStatefulWidget {
  final WithdrawalData data;

  const ProcessingWithdrawalScreen({super.key, required this.data});

  @override
  ConsumerState<ProcessingWithdrawalScreen> createState() =>
      _ProcessingWithdrawalScreenState();
}

class _ProcessingWithdrawalScreenState
    extends ConsumerState<ProcessingWithdrawalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _processWithdrawal();
  }

  Future<void> _processWithdrawal() async {
    try {
      final pin = widget.data.pin;
      if (pin == null || pin.isEmpty) {
        throw StateError("Withdrawal authentication is missing.");
      }
      final authState = ref.read(authProvider);
      final savingsId = widget.data.savingsId ?? '';
      final account = await ref.refresh(
        withdrawalAccountProvider(savingsId).future,
      );
      final rawBalance = account['balance'];
      final currentBalance = rawBalance is num
          ? rawBalance.toDouble()
          : double.tryParse(rawBalance?.toString().replaceAll(',', '') ?? '');
      if (currentBalance == null) {
        throw StateError('The savings balance could not be verified.');
      }
      final response = await ref
          .read(savingsServiceProvider)
          .withdrawSavings(
            phoneNumber: _toInternationalPhone(widget.data.phoneNumber),
            accountNumber: authState.userId ?? "",
            pin: pin,
            amount: widget.data.amount,
            currentBalance: currentBalance,
            imeiNumber: await ref
                .read(deviceIdentityServiceProvider)
                .getBackendDeviceNumber(),
            savingsId: widget.data.savingsId,
            channel: widget.data.channel,
            username:
                ref
                    .read(userProfileProvider)
                    .valueOrNull?['name']
                    ?.toString() ??
                'Member',
          );
      if (!mounted) return;
      final transactionId = response['transaction_id']?.toString();
      final newBalanceValue = response['new_balance'];
      final newBalance = newBalanceValue is num
          ? newBalanceValue.toDouble()
          : double.tryParse(newBalanceValue?.toString() ?? '');
      final updatedData = widget.data.copyWith(
        availableBalance: currentBalance,
        reference: transactionId,
        isPending: response['is_pending'] == true,
        processedAt: DateTime.tryParse(
          response['processed_at']?.toString() ?? '',
        ),
        newBalance: newBalance,
      );
      ref.invalidate(withdrawalAccountProvider(savingsId));
      await refreshMemberAccountData(ref);
      if (!mounted) return;
      context.push("/withdrawal/success", extra: updatedData);
    } catch (error) {
      if (!mounted) return;
      AppLogger.error('Withdrawal outcome could not be confirmed.', error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is AppException
                ? error.message
                : 'We could not confirm the withdrawal. Check your balance or transaction history before trying again.',
          ),
        ),
      );
      context.go('/withdrawal/review', extra: widget.data);
    }
  }

  String _toInternationalPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return '233${digits.substring(1)}';
    return digits;
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
      title: 'Processing Withdrawal',
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
