import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/modern_input.dart';

// ─── Internal account model ───────────────────────────────────────────────────

class _InternalAccount {
  final String id;
  final String name;
  final String typeLabel;
  final IconData icon;
  final Color color;
  final double balance;

  const _InternalAccount({
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.icon,
    required this.color,
    required this.balance,
  });
}

const List<_InternalAccount> _internalAccounts = [
  _InternalAccount(
    id: 'member',
    name: 'Member Savings',
    typeLabel: 'Savings',
    icon: Icons.savings_rounded,
    color: Color(0xFF2E8B57),
    balance: 1250.00,
  ),
  _InternalAccount(
    id: 'current',
    name: 'Current Account',
    typeLabel: 'Current',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF1976D2),
    balance: 8400.00,
  ),
  _InternalAccount(
    id: 'kiddy',
    name: 'Kiddy Savings',
    typeLabel: 'Savings',
    icon: Icons.child_care_rounded,
    color: Color(0xFFE64A19),
    balance: 320.00,
  ),
  _InternalAccount(
    id: 'fixed',
    name: 'Fixed Deposit',
    typeLabel: 'Fixed',
    icon: Icons.lock_clock_rounded,
    color: Color(0xFF6A1B9A),
    balance: 5000.00,
  ),
];

const List<int> _quickTransferAmounts = [50, 100, 200, 500];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String? _fromAccountId;
  String? _toAccountId;
  final _amountController = TextEditingController();
  bool _isSending = false;
  String _savedTransactionPin = '1234';

  @override
  void initState() {
    super.initState();
    _loadStoredPin();
  }

  Future<void> _loadStoredPin() async {
    final prefs = await SharedPreferences.getInstance();
    const possibleKeys = ['transaction_pin', 'user_pin', 'app_pin', 'pin'];
    for (final key in possibleKeys) {
      final value = prefs.getString(key)?.trim();
      if (value != null && value.length == 4) {
        if (!mounted) return;
        setState(() => _savedTransactionPin = value);
        return;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  _InternalAccount? _findAccountById(String? id) {
    if (id == null) return null;
    for (final account in _internalAccounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  _InternalAccount? get _fromAccount {
    return _findAccountById(_fromAccountId);
  }

  _InternalAccount? get _toAccount {
    return _findAccountById(_toAccountId);
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  bool get _canSubmit {
    final from = _fromAccount;
    if (from == null || _toAccountId == null) return false;
    if (_fromAccountId == _toAccountId) return false;
    if (_amount <= 0) return false;
    if (_amount > from.balance) return false;
    return true;
  }

  void _setQuickAmount(double amount) {
    setState(() => _amountController.text = amount.toStringAsFixed(2));
  }

  Future<void> _onConfirmTransferPressed() async {
    if (_isSending) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await _showTransferConfirmationSheet();
    if (!mounted || !confirmed) return;
    final navigator = GoRouter.of(context);
    _submit(navigator);
  }

  Future<bool> _showTransferConfirmationSheet() async {
    final fee = _amount * 0.005;
    final total = _amount + fee;
    final pinController = TextEditingController();
    var attemptsLeft = 3;
    var cooldownLeft = 0;
    String? pinError;
    var shakeTick = 0;
    Timer? cooldownTimer;
    var sheetActive = true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        var pin = '';
        var obscurePin = true;
        return StatefulBuilder(
          builder: (statefulContext, setSheetState) {
            final isPinValid = pin.length == 4;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.of(statefulContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Confirm Transfer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please review the details and enter your 4-digit PIN.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(
                          0.62,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ConfirmRow(
                      label: 'From Account',
                      value: _fromAccount?.name ?? '—',
                    ),
                    _ConfirmRow(
                      label: 'To Account',
                      value: _toAccount?.name ?? '—',
                    ),
                    const Divider(height: 24),
                    _ConfirmRow(
                      label: 'Amount',
                      value: 'GH₵ ${_amount.toStringAsFixed(2)}',
                    ),
                    _ConfirmRow(
                      label: 'Fee (0.5%)',
                      value: 'GH₵ ${fee.toStringAsFixed(2)}',
                    ),
                    _ConfirmRow(
                      label: 'Total Debit',
                      value: 'GH₵ ${total.toStringAsFixed(2)}',
                      emphasize: true,
                    ),
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(shakeTick),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 360),
                      builder: (context, value, child) {
                        final dx = math.sin(value * math.pi * 6) * 8;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: TextField(
                        controller: pinController,
                        obscureText: obscurePin,
                        enableInteractiveSelection: false,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        enabled: cooldownLeft == 0,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => setSheetState(() {
                          pin = value.trim();
                          if (pinError != null) pinError = null;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Transaction PIN',
                          hintText: 'Enter 4-digit PIN',
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setSheetState(() => obscurePin = !obscurePin),
                            icon: Icon(
                              obscurePin
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (cooldownLeft > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Too many attempts. Try again in ${cooldownLeft}s.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    else if (pinError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          pinError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    else if (!isPinValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'PIN must be exactly 4 digits.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: isPinValid && cooldownLeft == 0
                          ? () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (pin == _savedTransactionPin) {
                                Navigator.of(statefulContext).pop(true);
                                return;
                              }
                              setSheetState(() {
                                shakeTick++;
                                attemptsLeft--;
                                if (attemptsLeft > 0) {
                                  pinError =
                                      'Incorrect PIN. $attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} left.';
                                } else {
                                  pinError =
                                      'PIN locked for 30s due to too many attempts.';
                                  cooldownLeft = 30;
                                  attemptsLeft = 3;
                                  cooldownTimer?.cancel();
                                  cooldownTimer = Timer.periodic(
                                    const Duration(seconds: 1),
                                    (timer) {
                                      if (!sheetActive) {
                                        timer.cancel();
                                        return;
                                      }
                                      setSheetState(() {
                                        cooldownLeft--;
                                        if (cooldownLeft <= 0) {
                                          cooldownLeft = 0;
                                          pinError = null;
                                          pinController.clear();
                                          pin = '';
                                          timer.cancel();
                                        }
                                      });
                                    },
                                  );
                                }
                              });
                            }
                          : null,
                      icon: const Icon(Icons.verified_rounded),
                      label: Text(
                        cooldownLeft > 0
                            ? 'Locked (${cooldownLeft}s)'
                            : 'Yes, Transfer',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(statefulContext).pop(false),
                      child: const Text('Review Again'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    sheetActive = false;
    cooldownTimer?.cancel();

    return result ?? false;
  }

  void _submit(GoRouter navigator) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isSending = false);
    if (!mounted) return;
    final now = DateTime.now();
    navigator.go(
      '/payment-success',
      extra: {
        'amount': _amount,
        'processedAt': now.toIso8601String(),
        'reference': 'TRF#${now.millisecondsSinceEpoch}',
        'title': 'Transfer Successful',
        'message': 'Your transfer has been completed successfully.',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    final fee = _amount * 0.005;
    final totalDebit = _amount + fee;
    const gap = SizedBox(height: 12);
    final accent = theme.colorScheme.primary;

    return AppScaffold(
      title: 'Transfer',
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -8,
            child: IgnorePointer(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacitySafe(0.06),
                ),
              ),
            ),
          ),
          Positioned(
            left: -18,
            top: 210,
            child: IgnorePointer(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withOpacitySafe(0.04),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 980 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PageIntro(theme: theme),
                    gap,

                    // From Account
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'From Account',
                            subtitle: 'Select the account to debit',
                            icon: Icons.arrow_upward_rounded,
                            theme: theme,
                            accentColor: accent,
                          ),
                          const SizedBox(height: 12),
                          ..._internalAccounts.map(
                            (acc) => _AccountTile(
                              account: acc,
                              selected: _fromAccountId == acc.id,
                              disabled: _toAccountId == acc.id,
                              onTap: () => setState(() {
                                _fromAccountId = acc.id;
                                if (_toAccountId == acc.id) _toAccountId = null;
                              }),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow divider
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withOpacitySafe(0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withOpacitySafe(0.20),
                            ),
                          ),
                          child: Icon(
                            Icons.swap_vert_rounded,
                            color: accent,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    // To Account
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'To Account',
                            subtitle: 'Select the account to credit',
                            icon: Icons.arrow_downward_rounded,
                            theme: theme,
                            accentColor: accent,
                          ),
                          const SizedBox(height: 12),
                          ..._internalAccounts.map(
                            (acc) => _AccountTile(
                              account: acc,
                              selected: _toAccountId == acc.id,
                              disabled: _fromAccountId == acc.id,
                              onTap: () => setState(() {
                                _toAccountId = acc.id;
                                if (_fromAccountId == acc.id) {
                                  _fromAccountId = null;
                                }
                              }),
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                    ),

                    gap,

                    // Amount entry
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'Amount',
                            subtitle: _fromAccount != null
                                ? 'Available: GH₵ ${_fromAccount!.balance.toStringAsFixed(2)}'
                                : 'Enter the amount to transfer',
                            icon: Icons.payments_rounded,
                            theme: theme,
                            accentColor: accent,
                          ),
                          const SizedBox(height: 12),
                          ModernInput(
                            label: 'Transfer Amount',
                            hintText: '0.00',
                            controller: _amountController,
                            enableInteractiveSelection: false,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixText: 'GH₵ ',
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_fromAccount != null &&
                              _amount > _fromAccount!.balance) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Amount exceeds available balance.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    gap,

                    if (!isTablet) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              title: 'Quick Amount',
                              subtitle: 'Tap an amount to auto-fill',
                              icon: Icons.flash_on_rounded,
                              theme: theme,
                              accentColor: accent,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _quickTransferAmounts
                                  .map(
                                    (amount) => ActionChip(
                                      label: Text('GH₵ $amount'),
                                      onPressed: () =>
                                          _setQuickAmount(amount.toDouble()),
                                      avatar: Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: accent,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      gap,
                      _FeeSummary(amount: _amount, theme: theme),
                      const SizedBox(height: 18),
                      _ConfirmButton(
                        canSubmit: _canSubmit,
                        isSending: _isSending,
                        accent: accent,
                        theme: theme,
                        totalDebit: totalDebit,
                        onPressed: _onConfirmTransferPressed,
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    title: 'Quick Amount',
                                    subtitle: 'Tap an amount to auto-fill',
                                    icon: Icons.flash_on_rounded,
                                    theme: theme,
                                    accentColor: accent,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _quickTransferAmounts
                                        .map(
                                          (amount) => ActionChip(
                                            label: Text('GH₵ $amount'),
                                            onPressed: () => _setQuickAmount(
                                              amount.toDouble(),
                                            ),
                                            avatar: Icon(
                                              Icons.bolt_rounded,
                                              size: 16,
                                              color: accent,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _FeeSummary(amount: _amount, theme: theme),
                                const SizedBox(height: 18),
                                _ConfirmButton(
                                  canSubmit: _canSubmit,
                                  isSending: _isSending,
                                  accent: accent,
                                  theme: theme,
                                  totalDebit: totalDebit,
                                  onPressed: _onConfirmTransferPressed,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account tile ─────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final _InternalAccount account;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  final ThemeData theme;

  const _AccountTile({
    required this.account,
    required this.selected,
    required this.disabled,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? theme.colorScheme.onSurface.withOpacitySafe(0.22)
        : account.color;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : disabled
              ? theme.colorScheme.outline.withValues(alpha: 0.04)
              : theme.colorScheme.outline.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.40)
                : theme.colorScheme.outline.withValues(alpha: 0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(account.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? theme.colorScheme.onSurface.withOpacitySafe(0.35)
                          : null,
                    ),
                  ),
                  Text(
                    account.typeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: disabled
                          ? theme.colorScheme.onSurface.withOpacitySafe(0.28)
                          : color.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'GH₵ ${account.balance.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? theme.colorScheme.onSurface.withOpacitySafe(0.28)
                        : null,
                  ),
                ),
                if (disabled)
                  Text(
                    'Not available',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.35),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? color
                  : theme.colorScheme.onSurface.withOpacitySafe(0.25),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm button ───────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  final bool canSubmit;
  final bool isSending;
  final Color accent;
  final ThemeData theme;
  final double totalDebit;
  final VoidCallback onPressed;

  const _ConfirmButton({
    required this.canSubmit,
    required this.isSending,
    required this.accent,
    required this.theme,
    required this.totalDebit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: canSubmit
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: FilledButton.icon(
        onPressed: canSubmit ? (isSending ? null : onPressed) : null,
        icon: isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.swap_horiz_rounded),
        label: Text(
          isSending
              ? 'Processing...'
              : totalDebit > 0
              ? 'Confirm Transfer (GH₵ ${totalDebit.toStringAsFixed(2)})'
              : 'Confirm Transfer',
        ),
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─── Shared helper widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final ThemeData theme;
  final Color? accentColor;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theme,
    this.accentColor,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: (accentColor ?? theme.colorScheme.primary).withOpacitySafe(
            0.09,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: accentColor ?? theme.colorScheme.primary,
          size: 22,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.55),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _ConfirmRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.65),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: emphasize ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  final ThemeData theme;
  const _PageIntro({required this.theme});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withOpacitySafe(0.82),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withOpacitySafe(0.2),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Internal Transfer',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Move funds between your MyFinance accounts instantly.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeeSummary extends StatelessWidget {
  final double amount;
  final ThemeData theme;
  const _FeeSummary({required this.amount, required this.theme});
  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    final fee = amount * 0.005;
    final total = amount + fee;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Fee Summary',
            subtitle: 'Review fees before confirming',
            icon: Icons.receipt_long_rounded,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _fr('Transfer Amount', 'GH₵ ${amount.toStringAsFixed(2)}', theme),
          const SizedBox(height: 8),
          _fr(
            'Internal Fee (0.5%)',
            'GH₵ ${fee.toStringAsFixed(2)}',
            theme,
            isSubtle: true,
          ),
          Divider(
            height: 20,
            color: theme.colorScheme.outline.withOpacitySafe(0.15),
          ),
          _fr(
            'Total Debit',
            'GH₵ ${total.toStringAsFixed(2)}',
            theme,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _fr(
    String label,
    String value,
    ThemeData theme, {
    bool isSubtle = false,
    bool isBold = false,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSubtle
              ? theme.colorScheme.onSurface.withOpacitySafe(0.55)
              : null,
        ),
      ),
      Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: isBold ? theme.colorScheme.primary : null,
        ),
      ),
    ],
  );
}
