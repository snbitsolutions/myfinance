import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';
import '../../core/app_card.dart';
import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import '../../core/models/notification_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String? sourceLabel;
  final String? returnRoute;

  const PaymentScreen({super.key, this.sourceLabel, this.returnRoute});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _paymentMethods = ['Account', 'MoMo'];
  static const _momoProviders = [
    'MTN MoMo',
    'Telecel Cash',
    'AirtelTigo Money',
  ];

  static const _shareSourceAccounts = [
    'Member Savings',
    'Current Savings',
    'Available Accounts',
  ];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _momoPhoneController = TextEditingController();
  String _method = _paymentMethods.first;
  bool _isSubmitting = false;
  String _selectedShareAccount = _shareSourceAccounts.first;
  String _selectedInternalAccount = _shareSourceAccounts.first;
  String _selectedMomoProvider = _momoProviders.first;

  bool _isValidMomoNumber(String value) {
    final phone = value.trim();
    return RegExp(r'^0\d{9}$').hasMatch(phone);
  }

  String _resolveReturnRoute(String? explicitRoute) {
    final normalized = (explicitRoute ?? '').trim();
    if (normalized.isNotEmpty) {
      return normalized.startsWith('/') ? normalized : '/$normalized';
    }

    final isDepositFlow = widget.sourceLabel == 'Deposit';
    return isDepositFlow ? '/savings' : '/home';
  }

  Future<void> _handleProceed() async {
    if (_isSubmitting) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final useExistingAccount = widget.sourceLabel == 'Existing account';
    final isMomo = !useExistingAccount && _method == 'MoMo';
    final momoPhone = _momoPhoneController.text.trim();
    final canProceed = amount > 0 && (!isMomo || _isValidMomoNumber(momoPhone));

    if (!canProceed) return;

    setState(() => _isSubmitting = true);
    try {
      final authState = ref.read(authProvider);
      final accountNumber = authState.userId ?? '';
      final phoneNumber = authState.userEmail ?? '';

      final response = await ref
          .read(paymentServiceProvider)
          .chargePayment(
            accountNumber: accountNumber,
            phoneNumber: phoneNumber,
            amount: amount,
            paymentMethod: _method,
            momoPhoneNumber: isMomo ? momoPhone : null,
          );

      if (!mounted) return;
      final statusValue = response['status'];
      final isSuccess =
          statusValue == 'success' ||
          statusValue == 1 ||
          statusValue == '1' ||
          (statusValue is String && statusValue.toLowerCase() == 'success') ||
          (response['data'] is Map &&
              (response['data'] as Map)['status'] == 'success');

      if (isSuccess) {
        await NotificationService.instance.addNotification(
          AppNotification(
            id: 'payment_success_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Payment completed',
            message:
                'Your payment of GH₵${amount.toStringAsFixed(2)} was processed successfully.',
            timestamp: DateTime.now(),
            type: AppNotificationType.transaction,
            read: false,
          ),
        );
        if (!mounted) return;
        final returnRoute = _resolveReturnRoute(widget.returnRoute);
        final isSavingsReturn = returnRoute.startsWith('/savings');
        final successUri = Uri(
          path: '/payment-success',
          queryParameters: {'returnRoute': returnRoute},
        );
        context.go(
          successUri.toString(),
          extra: {
            'amount': amount,
            'processedAt': DateTime.now().toIso8601String(),
            'reference':
                response['transaction_id'] ??
                response['reference'] ??
                response['transactionId'] ??
                'PAY#${DateTime.now().millisecondsSinceEpoch}',
            'title': widget.sourceLabel == 'Deposit'
                ? 'Deposit Successful'
                : 'Payment Successful',
            'message':
                response['message'] ??
                (widget.sourceLabel == 'Deposit'
                    ? 'Your deposit has been credited to your account.'
                    : 'Your transaction was completed successfully.'),
            'primaryActionRoute': returnRoute,
            'primaryActionLabel': isSavingsReturn ? 'Done' : 'Go Home',
            'secondaryActionLabel': widget.sourceLabel == 'Deposit'
                ? 'View Receipt'
                : null,
            'secondaryActionRoute': widget.sourceLabel == 'Deposit'
                ? '/payment-receipt'
                : null,
            'account': _selectedInternalAccount,
            'paymentMethod': isMomo
                ? '$_method ($_selectedMomoProvider)'
                : '$_method ($_selectedInternalAccount)',
            'newBalance': response['new_balance'],
          },
        );
      } else {
        await NotificationService.instance.addNotification(
          AppNotification(
            id: 'payment_failed_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Payment needs attention',
            message:
                'Your payment of GH₵${amount.toStringAsFixed(2)} could not be completed.',
            timestamp: DateTime.now(),
            type: AppNotificationType.security,
            read: false,
          ),
        );
        if (!mounted) return;
        final returnRoute = _resolveReturnRoute(widget.returnRoute);
        context.go(
          '/payment-failed?returnRoute=${Uri.encodeComponent(returnRoute)}',
          extra: {
            'amount': amount,
            'message':
                response['message'] ?? 'Your payment could not be completed.',
            'returnRoute': returnRoute,
            'isDeposit': widget.sourceLabel == 'Deposit',
          },
        );
      }
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to process payment right now.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _momoPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amt = double.tryParse(_amountController.text) ?? 0;
    final useExistingAccount = widget.sourceLabel == 'Existing account';
    final isInvestment = widget.sourceLabel == 'Investment';
    final isMomo = !useExistingAccount && _method == 'MoMo';
    final isAccountMethod = !useExistingAccount && _method == 'Account';
    final momoPhone = _momoPhoneController.text.trim();
    final isMomoPhoneValid = _isValidMomoNumber(momoPhone);
    final showMomoPhoneError =
        isMomo && momoPhone.isNotEmpty && !isMomoPhoneValid;
    final canProceed = amt > 0 && (!isMomo || isMomoPhoneValid);
    final selectedSource = useExistingAccount
        ? _selectedShareAccount
        : _method == 'Account'
        ? '$_method ($_selectedInternalAccount)'
        : '$_method ($_selectedMomoProvider)';

    return AppScaffold(
      title: widget.sourceLabel == 'Deposit'
          ? 'Deposit'
          : useExistingAccount
          ? 'Buy Shares'
          : isInvestment
          ? 'Invest'
          : 'Payment',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;
          final content = SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  _PaymentHero(
                    theme: theme,
                    method: selectedSource,
                    subtitle: useExistingAccount || isInvestment
                        ? 'Selected account'
                        : 'Selected method',
                  ),

                  const SizedBox(height: 16),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PaymentSectionHeader(
                          title: widget.sourceLabel == 'Deposit'
                              ? 'Deposit Amount'
                              : 'Amount',
                          subtitle: widget.sourceLabel == 'Deposit'
                              ? 'Enter how much you want to deposit'
                              : 'Enter how much you want to pay',
                          icon: Icons.payments_rounded,
                          theme: theme,
                        ),
                        const SizedBox(height: 10),
                        ModernInput(
                          label: widget.sourceLabel == 'Deposit'
                              ? 'Amount to Deposit'
                              : 'Amount to Pay',
                          hintText: 'e.g., 500',
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          prefixText: 'GH₵ ',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        _PaymentSectionHeader(
                          title: useExistingAccount
                              ? 'Source Account'
                              : 'Payment Method',
                          subtitle: useExistingAccount
                              ? 'Funds will be debited from your existing account.'
                              : isInvestment
                              ? 'Choose how you want to make this investment.'
                              : 'Choose your preferred payment method.',
                          icon: Icons.account_balance_wallet_rounded,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        if (useExistingAccount)
                          _PaymentDropdownShell(
                            theme: theme,
                            child: DropdownButton<String>(
                              value: _selectedShareAccount,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              items: _shareSourceAccounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account,
                                      child: Row(
                                        children: [
                                          Icon(
                                            account == 'Member Savings'
                                                ? Icons.savings_rounded
                                                : account == 'Current Savings'
                                                ? Icons
                                                      .account_balance_wallet_rounded
                                                : Icons.account_tree_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(account),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedShareAccount =
                                    v ?? _selectedShareAccount,
                              ),
                            ),
                          )
                        else
                          _PaymentDropdownShell(
                            theme: theme,
                            child: DropdownButton<String>(
                              value: _method,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              items: _paymentMethods
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Row(
                                        children: [
                                          Icon(
                                            m == 'Account'
                                                ? Icons
                                                      .account_balance_wallet_rounded
                                                : m == 'MoMo'
                                                ? Icons.phone_android_rounded
                                                : Icons.account_balance_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(m),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _method = v ?? _method),
                            ),
                          ),
                        if (isAccountMethod) ...[
                          const SizedBox(height: 12),
                          _PaymentSectionHeader(
                            title: 'Account',
                            subtitle:
                                'Select the account to debit for this payment.',
                            icon: Icons.account_balance_rounded,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _PaymentDropdownShell(
                            theme: theme,
                            child: DropdownButton<String>(
                              value: _selectedInternalAccount,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              items: _shareSourceAccounts
                                  .map(
                                    (account) => DropdownMenuItem(
                                      value: account,
                                      child: Row(
                                        children: [
                                          Icon(
                                            account == 'Member Savings'
                                                ? Icons.savings_rounded
                                                : account == 'Current Savings'
                                                ? Icons
                                                      .account_balance_wallet_rounded
                                                : Icons.account_tree_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(account),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedInternalAccount =
                                    v ?? _selectedInternalAccount,
                              ),
                            ),
                          ),
                        ],
                        if (isMomo) ...[
                          const SizedBox(height: 12),
                          _PaymentSectionHeader(
                            title: 'MoMo Details',
                            subtitle:
                                'Select provider and enter recipient number.',
                            icon: Icons.phone_android_rounded,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _PaymentDropdownShell(
                            theme: theme,
                            child: DropdownButton<String>(
                              value: _selectedMomoProvider,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              items: _momoProviders
                                  .map(
                                    (provider) => DropdownMenuItem(
                                      value: provider,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.sim_card_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(provider),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => _selectedMomoProvider =
                                    v ?? _selectedMomoProvider,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ModernInput(
                            label: 'MoMo Number',
                            hintText: 'e.g., 0241234567',
                            controller: _momoPhoneController,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              final digitsOnly = value.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              final normalized = digitsOnly.length > 10
                                  ? digitsOnly.substring(0, 10)
                                  : digitsOnly;
                              if (normalized != value) {
                                _momoPhoneController.value = TextEditingValue(
                                  text: normalized,
                                  selection: TextSelection.collapsed(
                                    offset: normalized.length,
                                  ),
                                );
                              }
                              setState(() {});
                            },
                          ),
                          if (showMomoPhoneError) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Enter a valid Ghana number (10 digits, starts with 0).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                        if (amt > 0) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacitySafe(0.2),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withOpacitySafe(0.18),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.sourceLabel == 'Deposit'
                                          ? 'Deposit Summary'
                                          : 'Payment Summary',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.sourceLabel == 'Deposit'
                                          ? 'Amount Deposited'
                                          : 'Total',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'GH₵${amt.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  useExistingAccount
                                      ? 'Source: $selectedSource'
                                      : isInvestment
                                      ? 'Investment method: $selectedSource'
                                      : 'Method: $selectedSource',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacitySafe(0.6),
                                  ),
                                ),
                                if (isMomo) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'MoMo number: ${momoPhone.isEmpty ? '-' : momoPhone}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacitySafe(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: canProceed && !_isSubmitting
                          ? _handleProceed
                          : null,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_outline_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Processing...'
                            : widget.sourceLabel == 'Deposit'
                            ? 'Make Deposit'
                            : 'Proceed to Payment',
                      ),
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (isTablet) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }
}

class _PaymentHero extends StatelessWidget {
  final ThemeData theme;
  final String method;
  final String subtitle;

  const _PaymentHero({
    required this.theme,
    required this.method,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacitySafe(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacitySafe(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacitySafe(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Checkout',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$subtitle: $method',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacitySafe(0.92),
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

class _PaymentSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeData theme;

  const _PaymentSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacitySafe(0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentDropdownShell extends StatelessWidget {
  final ThemeData theme;
  final Widget child;

  const _PaymentDropdownShell({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacitySafe(0.35),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacitySafe(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
