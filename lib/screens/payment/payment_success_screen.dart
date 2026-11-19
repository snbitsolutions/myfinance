import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/color_ext.dart';
import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/providers/app_providers.dart';
import 'package:go_router/go_router.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final double? amount;
  final DateTime? processedAt;
  final String? reference;
  final String? title;
  final String? message;
  final String? primaryActionLabel;
  final String? primaryActionRoute;
  final String? secondaryActionLabel;
  final String? secondaryActionRoute;
  final String? account;
  final String? paymentMethod;
  final double? newBalance;
  final bool isPending;

  const PaymentSuccessScreen({
    super.key,
    this.amount,
    this.processedAt,
    this.reference,
    this.title,
    this.message,
    this.primaryActionLabel,
    this.primaryActionRoute,
    this.secondaryActionLabel,
    this.secondaryActionRoute,
    this.account,
    this.paymentMethod,
    this.newBalance,
    this.isPending = false,
  });

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  static const _statusCheckInterval = Duration(seconds: 10);
  static const _maxAutomaticStatusChecks = 6;

  Timer? _statusCheckTimer;
  int _automaticStatusChecks = 0;
  bool _isCheckingStatus = false;
  bool _isConfirmed = false;
  bool _isFailed = false;
  String? _statusCheckMessage;

  bool get _hasReference =>
      widget.reference != null && widget.reference!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.isPending && _hasReference) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkTransactionStatus();
      });
      _statusCheckTimer = Timer.periodic(_statusCheckInterval, (_) {
        if (_automaticStatusChecks >= _maxAutomaticStatusChecks) {
          _statusCheckTimer?.cancel();
          return;
        }
        _automaticStatusChecks++;
        _checkTransactionStatus();
      });
    }
  }

  Future<void> _checkTransactionStatus() async {
    if (!mounted ||
        !widget.isPending ||
        _isConfirmed ||
        _isFailed ||
        !_hasReference) {
      return;
    }
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
      _statusCheckMessage = null;
    });

    try {
      ref.invalidate(transactionsProvider);
      final transactions = await ref.read(transactionsProvider.future);
      if (!mounted) return;

      final reference = widget.reference!.trim().toLowerCase();
      final matchingTransaction = transactions.where((transaction) {
        for (final key in const [
          'transaction_id',
          'transactionId',
          'reference',
          'trans_id',
          'id',
          'external_transaction_id',
          'client_reference',
        ]) {
          final transactionReference = transaction[key]
              ?.toString()
              .trim()
              .toLowerCase();
          if (transactionReference == reference) return true;
        }
        return false;
      }).firstOrNull;
      String? status;
      if (matchingTransaction != null) {
        for (final key in const [
          'status',
          'state',
          'transaction_status',
          'payment_status',
        ]) {
          final value = matchingTransaction[key]?.toString().trim();
          if (value != null && value.isNotEmpty) {
            status = value.toLowerCase();
            break;
          }
        }
      }

      if (const {
        '1',
        'complete',
        'completed',
        'confirmed',
        'done',
        'paid',
        'success',
        'successful',
        'approved',
        'settled',
      }.contains(status)) {
        _statusCheckTimer?.cancel();
        setState(() => _isConfirmed = true);
        await refreshMemberAccountData(ref);
      } else if (status == 'false' ||
          const {
            'cancelled',
            'canceled',
            'declined',
            'denied',
            'error',
            'expired',
            'failed',
            'failure',
            'rejected',
          }.contains(status)) {
        _statusCheckTimer?.cancel();
        setState(() => _isFailed = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusCheckMessage =
              'Could not check the latest status. Your request remains pending.';
        });
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.isPending && !_isConfirmed && !_isFailed;
    return _PaymentSuccessContent(
      amount: widget.amount,
      processedAt: widget.processedAt,
      reference: widget.reference,
      title: _isConfirmed
          ? 'Deposit Successful'
          : _isFailed
          ? 'Deposit Failed'
          : widget.title,
      message: _isConfirmed
          ? 'The provider confirmed your deposit.'
          : _isFailed
          ? 'The provider reported that your deposit failed. The amount was not deposited.'
          : widget.message,
      primaryActionLabel: widget.primaryActionLabel,
      primaryActionRoute: widget.primaryActionRoute,
      secondaryActionLabel: widget.secondaryActionLabel,
      secondaryActionRoute: widget.secondaryActionRoute,
      account: widget.account,
      paymentMethod: widget.paymentMethod,
      newBalance: widget.newBalance,
      isPending: isPending,
      isFailed: _isFailed,
      isCheckingStatus: _isCheckingStatus,
      statusCheckMessage: _statusCheckMessage,
      onCheckStatus: _checkTransactionStatus,
    );
  }
}

class _PaymentSuccessContent extends StatelessWidget {
  final double? amount;
  final DateTime? processedAt;
  final String? reference;
  final String? title;
  final String? message;
  final String? primaryActionLabel;
  final String? primaryActionRoute;
  final String? secondaryActionLabel;
  final String? secondaryActionRoute;
  final String? account;
  final String? paymentMethod;
  final double? newBalance;
  final bool isPending;
  final bool isFailed;
  final bool isCheckingStatus;
  final String? statusCheckMessage;
  final VoidCallback onCheckStatus;

  const _PaymentSuccessContent({
    this.amount,
    this.processedAt,
    this.reference,
    this.title,
    this.message,
    this.primaryActionLabel,
    this.primaryActionRoute,
    this.secondaryActionLabel,
    this.secondaryActionRoute,
    this.account,
    this.paymentMethod,
    this.newBalance,
    this.isPending = false,
    this.isFailed = false,
    this.isCheckingStatus = false,
    this.statusCheckMessage,
    required this.onCheckStatus,
  });

  String _formatAmount() {
    final value = amount;
    return value == null ? 'Unavailable' : 'GH₵${value.toStringAsFixed(2)}';
  }

  String _formatReference() {
    if (reference != null && reference!.trim().isNotEmpty) {
      return reference!.trim();
    }
    return 'Unavailable';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTitle = (title != null && title!.trim().isNotEmpty)
        ? title!
        : isFailed
        ? 'Deposit Failed'
        : (isPending ? 'Deposit Pending' : 'Provider reported completion');
    final resolvedMessage = (message != null && message!.trim().isNotEmpty)
        ? message!
        : isFailed
        ? 'The provider reported that your deposit failed. The amount was not deposited.'
        : (isPending
              ? 'Your request is awaiting provider confirmation.'
              : 'The provider reported that the request completed.');
    final resolvedAccount = account ?? 'Member Savings';
    final resolvedPaymentMethod = paymentMethod ?? 'Mobile Money';
    final resolvedNewBalance = newBalance;

    return AppScaffold(
      title: 'Deposit Status',
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPending) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: isCheckingStatus ? null : onCheckStatus,
                    icon: isCheckingStatus
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      isCheckingStatus
                          ? 'Checking status...'
                          : 'Check transaction status',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    if (primaryActionRoute != null &&
                        primaryActionRoute!.trim().isNotEmpty) {
                      context.go(primaryActionRoute!);
                    } else {
                      context.go('/savings');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(primaryActionLabel ?? 'Done'),
                ),
              ),
              if (secondaryActionRoute != null &&
                  secondaryActionRoute!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => context.go(secondaryActionRoute!),
                  child: Text(secondaryActionLabel ?? 'Home'),
                ),
              ],
            ],
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Icon with decorative dots
            Stack(
              alignment: Alignment.center,
              children: [
                // Decorative dots scattered around
                ..._generateDecorativeDots(),
                // Center checkmark icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isFailed
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isFailed
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary)
                                .withOpacitySafe(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFailed
                        ? Icons.close_rounded
                        : isPending
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
              resolvedTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              resolvedMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Amount section (plain background)
            Text(
              _formatAmount(),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPending || isFailed ? 'Amount Requested' : 'Amount Deposited',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Transaction Details Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TransactionDetailRow('Account', resolvedAccount, theme),
                  _TransactionDetailRow('Method', resolvedPaymentMethod, theme),
                  _TransactionDetailRow('Reference', _formatReference(), theme),
                  _TransactionDetailRow('Date', _formatDateTime(), theme),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Balance Card
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
                              : isFailed
                              ? 'Balance not updated'
                              : 'Balance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPending || isFailed || resolvedNewBalance == null
                              ? 'Balance unavailable'
                              : 'GH₵${resolvedNewBalance.toStringAsFixed(2)}',
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
            if (statusCheckMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                statusCheckMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime() {
    final date = processedAt;
    if (date == null) return 'Unavailable';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final meridiem = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year} • $hour:${date.minute.toString().padLeft(2, '0')} $meridiem';
  }

  List<Widget> _generateDecorativeDots() {
    final colors = [
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF9C4),
      const Color(0xFFE0F2F1),
      const Color(0xFFF0F4C3),
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
}

class _TransactionDetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _TransactionDetailRow(this.label, this.value, this.theme) : icon = '';

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      'Account': Icons.account_balance_wallet_rounded,
      'Method': Icons.payment_rounded,
      'Reference': Icons.receipt_rounded,
      'Date': Icons.calendar_today_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            iconMap[label] ?? Icons.check_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
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
