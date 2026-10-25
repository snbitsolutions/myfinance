import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/modern_input.dart';
import '../../core/providers/app_providers.dart';

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

const List<int> _quickTransferAmounts = [50, 100, 200, 500];

/// Types of transfer destinations supported by the transfer flow.
enum TransferDestination { internal, member, bank, mobile }

// ─── Screen ───────────────────────────────────────────────────────────────────

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  String? _fromAccountId;
  String? _toAccountId;
  final _amountController = TextEditingController();

  // Selected destination (internal accounts, member, bank, or mobile money)
  TransferDestination _destination = TransferDestination.internal;

  // External recipient inputs
  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _memberIdController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  List<_InternalAccount> get _internalAccounts {
    final savings = ref.watch(savingsProvider).valueOrNull ?? const [];
    final shares = ref.watch(sharesProvider).valueOrNull ?? const [];
    final accounts = <_InternalAccount>[];

    void addAccounts(
      List<Map<String, dynamic>> items,
      String typeLabel,
      IconData icon,
      Color color,
    ) {
      for (final item in items) {
        final id =
            (item['id'] ?? item['product_id'] ?? item['savings_id'] ?? '')
                .toString()
                .trim();
        if (id.isEmpty) continue;
        final name =
            (item['pro_name'] ??
                    item['name'] ??
                    item['product_name'] ??
                    typeLabel)
                .toString()
                .trim();
        final rawBalance = item['balance'] ?? item['current_balance'] ?? 0;
        final balance = rawBalance is num
            ? rawBalance.toDouble()
            : double.tryParse(rawBalance.toString().replaceAll(',', '')) ?? 0;
        accounts.add(
          _InternalAccount(
            id: id,
            name: name,
            typeLabel: typeLabel,
            icon: icon,
            color: color,
            balance: balance,
          ),
        );
      }
    }

    addAccounts(
      savings,
      'Savings',
      Icons.savings_rounded,
      const Color(0xFF2E8B57),
    );
    addAccounts(
      shares,
      'Shares',
      Icons.pie_chart_rounded,
      const Color(0xFF1976D2),
    );
    return accounts;
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

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  bool get _canSubmit => false;

  void _setQuickAmount(double amount) {
    setState(() => _amountController.text = amount.toStringAsFixed(2));
  }

  Future<void> _onConfirmTransferPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_canSubmit) return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    final totalDebit = _amount;
    const gap = SizedBox(height: 12);
    final accent = theme.colorScheme.primary;

    return AppScaffold(
      title: 'Transfer',
      child: ColoredBox(
        color: const Color(0xFFF4F7F4),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
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

                            // Destination selector (Internal, Member, Bank, Mobile Money)
                            _TransferCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    title: 'Select Destination',
                                    subtitle:
                                        'Choose where you want to send money',
                                    icon: Icons.send_rounded,
                                    theme: theme,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Internal'),
                                        selected:
                                            _destination ==
                                            TransferDestination.internal,
                                        onSelected: (v) => setState(() {
                                          _destination =
                                              TransferDestination.internal;
                                          _toAccountId = null;
                                        }),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Member'),
                                        selected:
                                            _destination ==
                                            TransferDestination.member,
                                        onSelected: (v) => setState(() {
                                          _destination =
                                              TransferDestination.member;
                                          _toAccountId = null;
                                        }),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Bank'),
                                        selected:
                                            _destination ==
                                            TransferDestination.bank,
                                        onSelected: (v) => setState(() {
                                          _destination =
                                              TransferDestination.bank;
                                          _toAccountId = null;
                                        }),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Mobile Money'),
                                        selected:
                                            _destination ==
                                            TransferDestination.mobile,
                                        onSelected: (v) => setState(() {
                                          _destination =
                                              TransferDestination.mobile;
                                          _toAccountId = null;
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            gap,

                            // From Account
                            if (_destination == TransferDestination.internal)
                              _TransferCard(
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
                                          if (_toAccountId == acc.id) {
                                            _toAccountId = null;
                                          }
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                            if (_destination == TransferDestination.internal)
                              _TransferCard(
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

                            // Recipient selection for external destinations
                            if (_destination != TransferDestination.internal)
                              _TransferCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionHeader(
                                      title: 'Select Recipient',
                                      subtitle:
                                          'Choose or enter recipient details',
                                      icon: Icons.person_rounded,
                                      theme: theme,
                                    ),
                                    const SizedBox(height: 10),
                                    if (_destination ==
                                        TransferDestination.member) ...[
                                      ModernInput(
                                        label: 'Member ID or Phone',
                                        controller: _memberIdController,
                                        hintText: 'e.g. 00483921 or 0241234567',
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Member lookup is unavailable until recipient verification is connected to the backend.',
                                      ),
                                    ] else if (_destination ==
                                        TransferDestination.bank) ...[
                                      ModernInput(
                                        label: 'Bank Name',
                                        controller: _bankNameController,
                                        hintText: 'e.g. GCB Bank',
                                      ),
                                      const SizedBox(height: 8),
                                      ModernInput(
                                        label: 'Account Number',
                                        controller: _bankAccountController,
                                        hintText: 'e.g. 1234567890',
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Bank account verification is unavailable because no recipient lookup API is connected.',
                                      ),
                                    ] else if (_destination ==
                                        TransferDestination.mobile) ...[
                                      ModernInput(
                                        label: 'Mobile Number',
                                        controller: _mobileNumberController,
                                        hintText: 'e.g. 0241234567',
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mobile money recipient verification is unavailable because no lookup API is connected.',
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Recipient lookup is unavailable. External transfers cannot be submitted until the backend supports verification and processing.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.error,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                            // Amount entry
                            _TransferCard(
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
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
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
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
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
                              _TransferCard(
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
                                            (amount) => ChoiceChip(
                                              label: Text('GH₵ $amount'),
                                              selected: _amount == amount,
                                              showCheckmark: false,
                                              onSelected: (_) =>
                                                  _setQuickAmount(
                                                    amount.toDouble(),
                                                  ),
                                              labelStyle: TextStyle(
                                                color: _amount == amount
                                                    ? Colors.white
                                                    : const Color(0xFF3B5144),
                                                fontWeight: FontWeight.w700,
                                              ),
                                              backgroundColor: Colors.white,
                                              selectedColor: accent,
                                              side: BorderSide(
                                                color: _amount == amount
                                                    ? accent
                                                    : const Color(0xFFE1E9E3),
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
                            ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _TransferCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _SectionHeader(
                                            title: 'Quick Amount',
                                            subtitle:
                                                'Tap an amount to auto-fill',
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
                                                  (amount) => ChoiceChip(
                                                    label: Text('GH₵ $amount'),
                                                    selected: _amount == amount,
                                                    showCheckmark: false,
                                                    onSelected: (_) =>
                                                        _setQuickAmount(
                                                          amount.toDouble(),
                                                        ),
                                                    labelStyle: TextStyle(
                                                      color: _amount == amount
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF3B5144,
                                                            ),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    backgroundColor:
                                                        Colors.white,
                                                    selectedColor: accent,
                                                    side: BorderSide(
                                                      color: _amount == amount
                                                          ? accent
                                                          : const Color(
                                                              0xFFE1E9E3,
                                                            ),
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
                                        _FeeSummary(
                                          amount: _amount,
                                          theme: theme,
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
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                border: const Border(top: BorderSide(color: Color(0xFFE6ECE7))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 16,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _ConfirmButton(
                        canSubmit: _canSubmit,
                        accent: accent,
                        theme: theme,
                        totalDebit: totalDebit,
                        onPressed: _onConfirmTransferPressed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transfer processing is not available yet. No money will be moved.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF718077),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final Widget child;

  const _TransferCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EAE4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
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
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.40)
                : const Color(0xFFE8EEE9),
            width: selected ? 1.5 : 1,
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
                      fontSize: 13,
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
  final Color accent;
  final ThemeData theme;
  final double totalDebit;
  final VoidCallback onPressed;

  const _ConfirmButton({
    required this.canSubmit,
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
        onPressed: canSubmit ? onPressed : null,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: Text(
          totalDebit > 0
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

class _PageIntro extends StatelessWidget {
  final ThemeData theme;
  const _PageIntro({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF26734A), Color(0xFF164B35)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF164B35).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer money',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose where your money comes from and where it needs to go.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.4,
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

class _FeeSummary extends StatelessWidget {
  final double amount;
  final ThemeData theme;
  const _FeeSummary({required this.amount, required this.theme});
  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return _TransferCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Transfer Amount',
            subtitle: 'Fees and transfer limits are not available',
            icon: Icons.receipt_long_rounded,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _fr('Amount', 'GH₵ ${amount.toStringAsFixed(2)}', theme),
          const SizedBox(height: 8),
          Text(
            'Transfers are unavailable because the backend contract does not accept the selected accounts and amount. Fees and limits are also unconfirmed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
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
