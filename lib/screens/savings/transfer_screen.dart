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

enum _TransferTarget { bank, mobileMoney, personal }

const List<String> banksList = [
  'GCB Bank',
  'Ecobank Ghana',
  'Absa Ghana',
  'Zenith Bank Ghana',
  'Stanbic Bank Ghana',
  'Standard Chartered Ghana',
  'Agricultural Development Bank',
  'Fidelity Bank Ghana',
  'CalBank',
  'Republic Bank Ghana',
];

const List<String> mobileMoneyProvidersList = [
  'MTN Mobile Money',
  'Telecel Cash',
  'AirtelTigo Money',
];

class _TransferFavorite {
  final String id, target, title, subtitle, accountOrPhone, recipientName;
  final String? bankOrNetwork;
  _TransferFavorite({
    required this.id,
    required this.target,
    required this.title,
    required this.subtitle,
    this.bankOrNetwork,
    required this.accountOrPhone,
    required this.recipientName,
  });
}

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  _TransferTarget _target = _TransferTarget.bank;
  String? _selectedFavoriteId;
  bool _saveAsFavorite = false, _isSending = false, _isResolvingAccount = false;
  String _savedTransactionPin = '1234';

  final _bankAccountController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _bankAmountController = TextEditingController();
  String _selectedBank = banksList.first;

  final _mobileMoneyNumberController = TextEditingController();
  final _mobileMoneyNameController = TextEditingController();
  final _mobileMoneyAmountController = TextEditingController();
  String _selectedMobileMoneyProvider = mobileMoneyProvidersList.first;

  final _phoneController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _personalAmountController = TextEditingController();

  final List<_TransferFavorite> _favorites = [
    _TransferFavorite(
      id: '1',
      target: 'bank',
      title: 'Ama Boateng',
      subtitle: 'GCB Bank',
      bankOrNetwork: 'GCB Bank',
      accountOrPhone: '1234567890',
      recipientName: 'Ama Boateng',
    ),
    _TransferFavorite(
      id: '2',
      target: 'mobileMoney',
      title: 'Kwame Mensah',
      subtitle: 'MTN Mobile Money',
      bankOrNetwork: 'MTN Mobile Money',
      accountOrPhone: '0241234567',
      recipientName: 'Kwame Mensah',
    ),
  ];

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
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
    _bankAmountController.dispose();
    _mobileMoneyNumberController.dispose();
    _mobileMoneyNameController.dispose();
    _mobileMoneyAmountController.dispose();
    _phoneController.dispose();
    _recipientNameController.dispose();
    _personalAmountController.dispose();
    super.dispose();
  }

  String _targetLabel(_TransferTarget t) {
    if (t == _TransferTarget.bank) return 'Bank';
    if (t == _TransferTarget.mobileMoney) return 'Mobile Money';
    return 'Personal';
  }

  IconData _targetIcon(_TransferTarget t) {
    if (t == _TransferTarget.bank) return Icons.account_balance_rounded;
    if (t == _TransferTarget.mobileMoney) return Icons.phone_android_rounded;
    return Icons.person_rounded;
  }

  String _targetHelperText(_TransferTarget t) {
    if (t == _TransferTarget.bank)
      return 'Send money directly to a bank account';
    if (t == _TransferTarget.mobileMoney)
      return 'Send money to a mobile wallet';
    return 'Send money to another MyFinance user';
  }

  Color _accentColorForTarget(_TransferTarget t, ThemeData theme) {
    if (t == _TransferTarget.bank) return theme.colorScheme.primary;
    if (t == _TransferTarget.mobileMoney) return Colors.amber.shade700;
    return Colors.blue.shade600;
  }

  List<_TransferFavorite> get _favoritesForTarget {
    final key = _target == _TransferTarget.bank
        ? 'bank'
        : _target == _TransferTarget.mobileMoney
        ? 'mobileMoney'
        : 'personal';
    return _favorites.where((f) => f.target == key).toList();
  }

  void _applyFavorite(String? favoriteId) {
    if (favoriteId == null) return;
    final fav = _favorites.firstWhere((f) => f.id == favoriteId);
    setState(() {
      _selectedFavoriteId = favoriteId;
      if (_target == _TransferTarget.bank) {
        _selectedBank = fav.bankOrNetwork ?? banksList.first;
        _bankAccountController.text = fav.accountOrPhone;
        _bankAccountNameController.text = fav.recipientName;
      } else if (_target == _TransferTarget.mobileMoney) {
        _selectedMobileMoneyProvider =
            fav.bankOrNetwork ?? mobileMoneyProvidersList.first;
        _mobileMoneyNumberController.text = fav.accountOrPhone;
        _mobileMoneyNameController.text = fav.recipientName;
      } else {
        _phoneController.text = fav.accountOrPhone;
        _recipientNameController.text = fav.recipientName;
      }
    });
  }

  void _onBankAccountChanged(String val) {
    if (val.length >= 10) {
      setState(() => _isResolvingAccount = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isResolvingAccount = false;
          _bankAccountNameController.text = 'Ama Boateng';
        });
      });
    } else {
      setState(() => _bankAccountNameController.clear());
    }
  }

  void _onMobileMoneyNumberChanged(String val) {
    if (val.length >= 10) {
      setState(() => _isResolvingAccount = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isResolvingAccount = false;
          _mobileMoneyNameController.text = 'Kojo Asare';
        });
      });
    } else {
      setState(() => _mobileMoneyNameController.clear());
    }
  }

  void _onPhoneChanged(String val) {
    if (val.length >= 10) {
      setState(() => _isResolvingAccount = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isResolvingAccount = false;
          _recipientNameController.text = 'Abena Owusu';
        });
      });
    } else {
      setState(() => _recipientNameController.clear());
    }
  }

  bool get _bankCanSubmit {
    final amt = double.tryParse(_bankAmountController.text) ?? 0;
    return _bankAccountController.text.length >= 10 &&
        _bankAccountNameController.text.isNotEmpty &&
        amt > 0;
  }

  bool get _personalCanSubmit {
    final amt = double.tryParse(_personalAmountController.text) ?? 0;
    return _phoneController.text.length >= 10 &&
        _recipientNameController.text.isNotEmpty &&
        amt > 0;
  }

  bool get _mobileMoneyCanSubmit {
    final amt = double.tryParse(_mobileMoneyAmountController.text) ?? 0;
    return _mobileMoneyNumberController.text.length >= 10 &&
        _mobileMoneyNameController.text.isNotEmpty &&
        amt > 0;
  }

  String get _activeAmountText {
    if (_target == _TransferTarget.bank) return _bankAmountController.text;
    if (_target == _TransferTarget.mobileMoney)
      return _mobileMoneyAmountController.text;
    return _personalAmountController.text;
  }

  double get _activeAmount => double.tryParse(_activeAmountText) ?? 0;

  void _setQuickAmount(double amount) {
    final normalized = amount.toStringAsFixed(2);
    setState(() {
      if (_target == _TransferTarget.bank) {
        _bankAmountController.text = normalized;
      } else if (_target == _TransferTarget.mobileMoney) {
        _mobileMoneyAmountController.text = normalized;
      } else {
        _personalAmountController.text = normalized;
      }
    });
  }

  String get _activeRecipientName {
    if (_target == _TransferTarget.bank) return _bankAccountNameController.text;
    if (_target == _TransferTarget.mobileMoney) {
      return _mobileMoneyNameController.text;
    }
    return _recipientNameController.text;
  }

  String get _activeDestinationLabel {
    if (_target == _TransferTarget.bank) return _selectedBank;
    if (_target == _TransferTarget.mobileMoney) {
      return _selectedMobileMoneyProvider;
    }
    return 'MyFinance Personal';
  }

  String get _activeAccountOrPhone {
    if (_target == _TransferTarget.bank) return _bankAccountController.text;
    if (_target == _TransferTarget.mobileMoney) {
      return _mobileMoneyNumberController.text;
    }
    return _phoneController.text;
  }

  Future<void> _onConfirmTransferPressed() async {
    final confirmed = await _showTransferConfirmationSheet();
    if (!mounted || !confirmed) return;
    _submit();
  }

  Future<bool> _showTransferConfirmationSheet() async {
    final fee = _activeAmount * 0.01;
    final total = _activeAmount + fee;
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
                      label: 'Transfer Type',
                      value: _targetLabel(_target),
                    ),
                    _ConfirmRow(
                      label: 'Recipient',
                      value: _activeRecipientName,
                    ),
                    _ConfirmRow(
                      label: 'Destination',
                      value: _activeDestinationLabel,
                    ),
                    _ConfirmRow(
                      label: 'Account / Phone',
                      value: _activeAccountOrPhone,
                    ),
                    const Divider(height: 24),
                    _ConfirmRow(
                      label: 'Amount',
                      value: 'GH₵ ${_activeAmount.toStringAsFixed(2)}',
                    ),
                    _ConfirmRow(
                      label: 'Fee (1%)',
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
                              if (pin == _savedTransactionPin) {
                                Navigator.of(statefulContext).pop(true);
                                return;
                              }

                              setSheetState(() {
                                shakeTick++;
                                attemptsLeft--;
                                if (attemptsLeft > 0) {
                                  pinError =
                                      'Incorrect PIN. ${attemptsLeft} attempt${attemptsLeft == 1 ? '' : 's'} left.';
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
                            : 'Yes, Send Transfer',
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
    pinController.dispose();

    return result ?? false;
  }

  Future<void> _saveCurrentAsFavoriteIfNeeded() async {}

  void _submit() async {
    setState(() => _isSending = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _saveCurrentAsFavoriteIfNeeded();
    setState(() => _isSending = false);
    // After PIN confirmation, transfer always succeeds
    context.go('/payment-success');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit =
        (_bankCanSubmit && _target == _TransferTarget.bank) ||
        (_mobileMoneyCanSubmit && _target == _TransferTarget.mobileMoney) ||
        (_personalCanSubmit && _target == _TransferTarget.personal);
    const gap = SizedBox(height: 12);
    final accent = _accentColorForTarget(_target, theme);
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
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageIntro(theme: theme),
                gap,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Transfer Type',
                        subtitle: 'Select your preferred transfer destination',
                        icon: Icons.swap_horiz_rounded,
                        theme: theme,
                        accentColor: accent,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _TransferTarget.values
                            .map(
                              (t) => _TransferTypeChip(
                                label: _targetLabel(t),
                                icon: _targetIcon(t),
                                selected: _target == t,
                                onTap: () => setState(() {
                                  _target = t;
                                  _selectedFavoriteId = null;
                                }),
                                theme: theme,
                                accentColor: _accentColorForTarget(t, theme),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      _SelectedTargetInfo(
                        theme: theme,
                        icon: _targetIcon(_target),
                        label: _targetLabel(_target),
                        helperText: _targetHelperText(_target),
                        accentColor: accent,
                      ),
                    ],
                  ),
                ),
                gap,
                if (_favoritesForTarget.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Favorites',
                          subtitle: 'Select from your saved recipients',
                          icon: Icons.star_rounded,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _favoritesForTarget
                                .map(
                                  (fav) => Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () => _applyFavorite(fav.id),
                                      child: Container(
                                        width: 140,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _selectedFavoriteId == fav.id
                                              ? accent.withValues(alpha: 0.14)
                                              : theme.colorScheme.outline
                                                    .withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: _selectedFavoriteId == fav.id
                                                ? accent.withValues(alpha: 0.35)
                                                : theme.colorScheme.outline
                                                      .withValues(alpha: 0.15),
                                            width: _selectedFavoriteId == fav.id
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  _selectedFavoriteId == fav.id
                                                      ? Icons
                                                            .check_circle_rounded
                                                      : Icons
                                                            .account_circle_rounded,
                                                  size: 16,
                                                  color:
                                                      _selectedFavoriteId ==
                                                          fav.id
                                                      ? accent
                                                      : theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.45,
                                                            ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    fav.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 12,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.85,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              fav.subtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(
                                                          alpha: 0.55,
                                                        ),
                                                    fontSize: 10,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              fav.accountOrPhone,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: accent.withValues(
                                                      alpha: 0.75,
                                                    ),
                                                    fontSize: 10,
                                                    fontFamily: 'monospace',
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  gap,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Or enter new recipient details below',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.52,
                        ),
                      ),
                    ),
                  ),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _target == _TransferTarget.bank
                      ? _BankForm(
                          key: const ValueKey('bank'),
                          banks: banksList,
                          selectedBank: _selectedBank,
                          accountController: _bankAccountController,
                          accountNameController: _bankAccountNameController,
                          amountController: _bankAmountController,
                          isResolving: _isResolvingAccount,
                          onBankChanged: (b) => setState(
                            () => _selectedBank = b ?? _selectedBank,
                          ),
                          onAccountChanged: _onBankAccountChanged,
                          onAmountChanged: (_) => setState(() {}),
                        )
                      : _target == _TransferTarget.mobileMoney
                      ? _MobileMoneyForm(
                          key: const ValueKey('momo'),
                          providers: mobileMoneyProvidersList,
                          selectedProvider: _selectedMobileMoneyProvider,
                          numberController: _mobileMoneyNumberController,
                          recipientNameController: _mobileMoneyNameController,
                          amountController: _mobileMoneyAmountController,
                          isResolving: _isResolvingAccount,
                          onProviderChanged: (p) => setState(
                            () => _selectedMobileMoneyProvider =
                                p ?? _selectedMobileMoneyProvider,
                          ),
                          onNumberChanged: _onMobileMoneyNumberChanged,
                          onAmountChanged: (_) => setState(() {}),
                        )
                      : _PersonalForm(
                          key: const ValueKey('personal'),
                          phoneController: _phoneController,
                          recipientNameController: _recipientNameController,
                          amountController: _personalAmountController,
                          isResolving: _isResolvingAccount,
                          onPhoneChanged: _onPhoneChanged,
                          onAmountChanged: (_) => setState(() {}),
                        ),
                ),
                gap,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        title: 'Save Recipient',
                        subtitle:
                            'Save this recipient for easier future transfers',
                        icon: Icons.bookmark_add_rounded,
                        theme: theme,
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _saveAsFavorite,
                        onChanged: (v) => setState(() => _saveAsFavorite = v),
                        title: const Text('Save as Favorite'),
                        subtitle: Text(
                          _target == _TransferTarget.bank
                              ? 'Use this bank recipient again next time.'
                              : _target == _TransferTarget.mobileMoney
                              ? 'Use this mobile money recipient again next time.'
                              : 'Use this personal recipient again next time.',
                        ),
                        secondary: Icon(
                          _saveAsFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: _saveAsFavorite
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface.withOpacitySafe(
                                  0.55,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                gap,
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
                        children: [50, 100, 200, 500]
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
                _FeeSummary(amount: _activeAmount, theme: theme),
                const SizedBox(height: 18),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canSubmit
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.24,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: FilledButton.icon(
                    onPressed: canSubmit
                        ? (_isSending ? null : _onConfirmTransferPressed)
                        : null,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSending ? 'Processing...' : 'Confirm Transfer',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      Column(
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Send Money',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Transfer funds to a bank, mobile wallet, or another account.',
        style: theme.textTheme.bodyMedium,
      ),
    ],
  );
}

class _TransferTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color accentColor;
  const _TransferTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.theme,
    required this.accentColor,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? accentColor.withValues(alpha: 0.15)
            : theme.colorScheme.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? accentColor.withValues(alpha: 0.35)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected
                ? accentColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? accentColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SelectedTargetInfo extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label, helperText;
  final Color accentColor;
  const _SelectedTargetInfo({
    required this.theme,
    required this.icon,
    required this.label,
    required this.helperText,
    required this.accentColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: accentColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accentColor.withValues(alpha: 0.18)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                helperText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DropdownShell extends StatelessWidget {
  final ThemeData theme;
  final Widget child;
  const _DropdownShell({required this.theme, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: theme.colorScheme.outline.withOpacitySafe(0.13),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    child: child,
  );
}

class _ResolvedName extends StatelessWidget {
  final String name;
  final ThemeData theme;
  const _ResolvedName({required this.name, required this.theme});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.verified_rounded, color: theme.colorScheme.primary, size: 18),
      const SizedBox(width: 6),
      Text(
        name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    ],
  );
}

class _ResolvingIndicator extends StatelessWidget {
  final ThemeData theme;
  final String label;
  const _ResolvingIndicator({required this.theme, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    ],
  );
}

class _BankForm extends StatelessWidget {
  final List<String> banks;
  final String selectedBank;
  final TextEditingController accountController,
      accountNameController,
      amountController;
  final bool isResolving;
  final ValueChanged<String?> onBankChanged;
  final ValueChanged<String> onAccountChanged, onAmountChanged;
  const _BankForm({
    super.key,
    required this.banks,
    required this.selectedBank,
    required this.accountController,
    required this.accountNameController,
    required this.amountController,
    required this.isResolving,
    required this.onBankChanged,
    required this.onAccountChanged,
    required this.onAmountChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Bank Transfer Details',
            subtitle: 'Enter recipient bank and account details',
            icon: Icons.account_balance_rounded,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _DropdownShell(
            theme: theme,
            child: DropdownButton<String>(
              value: selectedBank,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
              ),
              items: banks
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: onBankChanged,
            ),
          ),
          const SizedBox(height: 16),
          ModernInput(
            label: 'Account Number',
            hintText: 'Enter 10-digit account number',
            controller: accountController,
            keyboardType: TextInputType.number,
            onChanged: onAccountChanged,
          ),
          const SizedBox(height: 12),
          if (isResolving) ...[
            _ResolvingIndicator(theme: theme, label: 'Resolving account...'),
            const SizedBox(height: 12),
          ] else if (accountNameController.text.isNotEmpty) ...[
            _ResolvedName(name: accountNameController.text, theme: theme),
            const SizedBox(height: 12),
          ],
          ModernInput(
            label: 'Amount',
            hintText: '0.00',
            controller: amountController,
            keyboardType: TextInputType.number,
            prefixText: 'GH₵ ',
            onChanged: onAmountChanged,
          ),
        ],
      ),
    );
  }
}

class _MobileMoneyForm extends StatelessWidget {
  final List<String> providers;
  final String selectedProvider;
  final TextEditingController numberController,
      recipientNameController,
      amountController;
  final bool isResolving;
  final ValueChanged<String?> onProviderChanged;
  final ValueChanged<String> onNumberChanged, onAmountChanged;
  const _MobileMoneyForm({
    super.key,
    required this.providers,
    required this.selectedProvider,
    required this.numberController,
    required this.recipientNameController,
    required this.amountController,
    required this.isResolving,
    required this.onProviderChanged,
    required this.onNumberChanged,
    required this.onAmountChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Mobile Money Details',
            subtitle: 'Enter recipient mobile wallet details',
            icon: Icons.phone_android_rounded,
            theme: theme,
          ),
          const SizedBox(height: 8),
          _DropdownShell(
            theme: theme,
            child: DropdownButton<String>(
              value: selectedProvider,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
              ),
              items: providers
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: onProviderChanged,
            ),
          ),
          const SizedBox(height: 16),
          ModernInput(
            label: 'Mobile Number',
            hintText: 'Enter 10-digit number',
            controller: numberController,
            keyboardType: TextInputType.phone,
            onChanged: onNumberChanged,
          ),
          const SizedBox(height: 12),
          if (isResolving) ...[
            _ResolvingIndicator(theme: theme, label: 'Resolving recipient...'),
            const SizedBox(height: 12),
          ] else if (recipientNameController.text.isNotEmpty) ...[
            _ResolvedName(name: recipientNameController.text, theme: theme),
            const SizedBox(height: 12),
          ],
          ModernInput(
            label: 'Amount',
            hintText: '0.00',
            controller: amountController,
            keyboardType: TextInputType.number,
            prefixText: 'GH₵ ',
            onChanged: onAmountChanged,
          ),
        ],
      ),
    );
  }
}

class _PersonalForm extends StatelessWidget {
  final TextEditingController phoneController,
      recipientNameController,
      amountController;
  final bool isResolving;
  final ValueChanged<String> onPhoneChanged, onAmountChanged;
  const _PersonalForm({
    super.key,
    required this.phoneController,
    required this.recipientNameController,
    required this.amountController,
    required this.isResolving,
    required this.onPhoneChanged,
    required this.onAmountChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Personal Account Details',
            subtitle: 'Enter recipient phone and amount',
            icon: Icons.person_rounded,
            theme: theme,
          ),
          const SizedBox(height: 8),
          ModernInput(
            label: 'Phone Number',
            hintText: 'Enter 10-digit number',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            onChanged: onPhoneChanged,
          ),
          const SizedBox(height: 12),
          if (isResolving) ...[
            _ResolvingIndicator(theme: theme, label: 'Resolving recipient...'),
            const SizedBox(height: 12),
          ] else if (recipientNameController.text.isNotEmpty) ...[
            _ResolvedName(name: recipientNameController.text, theme: theme),
            const SizedBox(height: 12),
          ],
          ModernInput(
            label: 'Amount',
            hintText: '0.00',
            controller: amountController,
            keyboardType: TextInputType.number,
            prefixText: 'GH₵ ',
            onChanged: onAmountChanged,
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
    final fee = amount * 0.01;
    final total = amount + fee;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Fee Summary',
            subtitle: 'Review fees before confirming your transfer',
            icon: Icons.receipt_long_rounded,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _fr('Transfer Amount', 'GH₵ ${amount.toStringAsFixed(2)}', theme),
          const SizedBox(height: 8),
          _fr(
            'Transaction Fee (1%)',
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
