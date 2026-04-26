import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import 'savings_model.dart';
import 'savings_storage.dart';

class CreateSavingsScreen extends StatefulWidget {
  final SavingsType? initialType;

  const CreateSavingsScreen({super.key, this.initialType});

  @override
  State<CreateSavingsScreen> createState() => _CreateSavingsScreenState();
}

class _CreateSavingsScreenState extends State<CreateSavingsScreen> {
  static const _quickTargets = <int>[1000, 2000, 5000, 10000];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  late SavingsType _selectedType;
  bool _autoSave = false;
  DateTime? _maturityDate;
  String? _nameError;
  String? _targetError;
  String? _maturityError;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? SavingsType.memberSaving;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _targetController.text.trim().isNotEmpty &&
      (_selectedType != SavingsType.fixedDeposit || _maturityDate != null) &&
      _nameError == null &&
      _targetError == null &&
      _maturityError == null;

  void _validateName(String value) {
    setState(() {
      _nameError = value.trim().isEmpty ? 'Goal name is required' : null;
    });
  }

  void _validateTarget(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _targetError = 'Target amount is required';
      } else if (double.tryParse(value) == null) {
        _targetError = 'Please enter a valid amount';
      } else if (double.parse(value) <= 0) {
        _targetError = 'Amount must be greater than 0';
      } else {
        _targetError = null;
      }
    });
  }

  void _validateMaturity() {
    setState(() {
      if (_selectedType == SavingsType.fixedDeposit && _maturityDate == null) {
        _maturityError = 'Maturity date is required';
      } else {
        _maturityError = null;
      }
    });
  }

  double get _calculatedFixedDepositRate {
    if (_selectedType != SavingsType.fixedDeposit || _maturityDate == null) {
      return AppConstants.defaultInterestRate;
    }

    final days = _maturityDate!.difference(DateTime.now()).inDays;
    if (days <= 180) return 4.0;
    if (days <= 365) return 5.0;
    if (days <= 730) return 6.5;
    return 7.5;
  }

  double get _projectedMaturityAmount {
    if (_selectedType != SavingsType.fixedDeposit) return 0;
    final target = double.tryParse(_targetController.text) ?? 0;
    final rate = _calculatedFixedDepositRate;
    if (target <= 0 || rate < 0) return 0;
    final years = _maturityDate != null
        ? _maturityDate!.difference(DateTime.now()).inDays / 365
        : 0;
    return target * (1 + (rate / 100) * years);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    void setQuickTarget(int amount) {
      final text = amount.toString();
      _targetController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      setState(() {});
    }

    return AppScaffold(
      title: 'Create Savings',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;
          final content = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start a New Savings Goal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose a plan, set a target, and grow steadily.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withOpacitySafe(0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedType.icon,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Savings Type',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedType.label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _selectedType.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModernInput(
                        label: 'Savings Goal',
                        hintText: 'e.g., Emergency Fund',
                        controller: _nameController,
                        prefixIcon: Icons.savings,
                        onChanged: _validateName,
                        errorText: _nameError,
                      ),
                      const SizedBox(height: 16),
                      ModernInput(
                        label: 'Target Amount',
                        hintText: 'e.g., 2000',
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        prefixText: 'GH₵ ',
                        onChanged: _validateTarget,
                        errorText: _targetError,
                        helperText: 'Set a realistic goal based on your budget',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickTargets
                            .map(
                              (amount) => ActionChip(
                                label: Text('GH₵$amount'),
                                avatar: const Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                ),
                                onPressed: () => setQuickTarget(amount),
                              ),
                            )
                            .toList(),
                      ),
                      if (_selectedType == SavingsType.fixedDeposit) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacitySafe(0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacitySafe(
                                0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.percent,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Interest Rate',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacitySafe(0.6),
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_calculatedFixedDepositRate.toStringAsFixed(1)}% p.a. (auto-calculated)',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );
                            if (selected != null) {
                              setState(() {
                                _maturityDate = selected;
                                _validateMaturity();
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _maturityError != null
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.outline.withOpacitySafe(
                                        0.3,
                                      ),
                                width: _maturityError != null ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: _maturityError != null
                                  ? theme.colorScheme.error.withOpacitySafe(
                                      0.05,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: _maturityError != null
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Maturity Date',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacitySafe(0.6),
                                            ),
                                      ),
                                      Text(
                                        _maturityDate != null
                                            ? '${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}'
                                            : 'Select date',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (_maturityError != null)
                                        Text(
                                          _maturityError!,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: theme.colorScheme.error,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_projectedMaturityAmount > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacitySafe(
                                0.08,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withOpacitySafe(0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Projected at Maturity',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacitySafe(0.6),
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'GH₵${_projectedMaturityAmount.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.trending_up,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withOpacitySafe(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacitySafe(
                                0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Switch(
                                value: _autoSave,
                                onChanged: (v) => setState(() => _autoSave = v),
                                activeThumbColor: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Enable Auto-Save',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      'Automatically save amounts monthly',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacitySafe(0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Summary Preview Card
                if (_nameController.text.trim().isNotEmpty)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Goal Name',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _nameController.text.trim(),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Target',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.7),
                              ),
                            ),
                            Text(
                              _targetController.text.isNotEmpty
                                  ? 'GH₵${_targetController.text}'
                                  : '—',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedType == SavingsType.fixedDeposit) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Interest Rate',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.7),
                                ),
                              ),
                              Text(
                                '${_calculatedFixedDepositRate.toStringAsFixed(1)}%',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Maturity Date',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.7),
                                ),
                              ),
                              Text(
                                _maturityDate != null
                                    ? '${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}'
                                    : '—',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Auto-Save',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.7),
                                ),
                              ),
                              Text(
                                _autoSave ? 'Enabled' : 'Disabled',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _autoSave
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                            .withOpacitySafe(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isFormValid
                        ? () async {
                            // Create the savings object
                            final newSavings = Savings(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              title: _nameController.text.trim(),
                              balance: 0, // Start with zero balance
                              target:
                                  double.tryParse(_targetController.text) ?? 0,
                              type: _selectedType,
                              interestRate:
                                  _selectedType == SavingsType.fixedDeposit
                                  ? _calculatedFixedDepositRate
                                  : null,
                              maturityDate:
                                  _selectedType == SavingsType.fixedDeposit
                                  ? _maturityDate
                                  : null,
                            );

                            await SavingsStorage.addGoal(newSavings);
                            if (!context.mounted) return;

                            // Navigate to success screen
                            context.pushNamed(
                              'savings-success',
                              extra: newSavings,
                            );
                          }
                        : null,
                    child: Text('Create ${_selectedType.label} Goal'),
                  ),
                ),
              ],
            ),
          );

          if (!isTablet) return content;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: content,
            ),
          );
        },
      ),
    );
  }
}
