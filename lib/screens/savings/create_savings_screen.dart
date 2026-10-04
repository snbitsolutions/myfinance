import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/layout/responsive.dart';
import '../../core/modern_input.dart';
import '../../core/models/notification_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';
import 'savings_model.dart';
import 'savings_storage.dart';

class CreateSavingsScreen extends ConsumerStatefulWidget {
  final SavingsType? initialType;

  const CreateSavingsScreen({super.key, this.initialType});

  @override
  ConsumerState<CreateSavingsScreen> createState() =>
      _CreateSavingsScreenState();
}

class _CreateSavingsScreenState extends ConsumerState<CreateSavingsScreen> {
  static const _quickTargets = <int>[1000, 2000, 5000, 10000];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  late SavingsType _selectedType;
  bool _autoSave = false;
  DateTime? _maturityDate;
  String? _nameError;
  String? _targetError;
  String? _maturityError;
  bool _isSubmitting = false;

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

  Future<void> _selectSavingsType() async {
    final selected = await showModalBottomSheet<SavingsType>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a savings type',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the account that best matches your goal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.65),
                  ),
                ),
                const SizedBox(height: 14),
                ...SavingsType.values.map(
                  (type) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withOpacitySafe(0.45),
                      child: Icon(type.icon, color: theme.colorScheme.primary),
                    ),
                    title: Text(
                      type.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(type.description),
                    trailing: _selectedType == type
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(type),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == _selectedType || !mounted) return;
    setState(() {
      _selectedType = selected;
      if (_selectedType != SavingsType.fixedDeposit) {
        _maturityDate = null;
        _maturityError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liveGoalName = _nameController.text.trim().isEmpty
        ? 'Your goal'
        : _nameController.text.trim();
    final liveTarget = _targetController.text.trim();
    final liveTargetLabel = liveTarget.isEmpty
        ? 'Set target'
        : 'GH₵$liveTarget';

    void setQuickTarget(int amount) {
      final text = amount.toString();
      _targetController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _validateTarget(text);
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
                              'Build Your Savings Plan',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set a target today and make progress with confidence.',
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacitySafe(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live goal snapshot',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.7,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSummaryPill(
                            theme,
                            label: _selectedType.label,
                            icon: _selectedType.icon,
                          ),
                          _buildSummaryPill(
                            theme,
                            label: liveTargetLabel,
                            icon: Icons.currency_exchange_rounded,
                            accent: liveTarget.isEmpty
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                          _buildSummaryPill(
                            theme,
                            label: _autoSave ? 'Auto-save on' : 'Manual plan',
                            icon: _autoSave ? Icons.auto_awesome : Icons.tune,
                            accent: _autoSave
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        liveGoalName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacitySafe(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildStepIndicator(
                        theme,
                        number: '1',
                        label: 'Plan',
                        active: true,
                      ),
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.primary.withOpacitySafe(0.2),
                        ),
                      ),
                      _buildStepIndicator(
                        theme,
                        number: '2',
                        label: 'Target',
                        active: _nameController.text.trim().isNotEmpty,
                      ),
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.primary.withOpacitySafe(0.2),
                        ),
                      ),
                      _buildStepIndicator(
                        theme,
                        number: '3',
                        label: 'Review',
                        active: _isFormValid,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeading(
                  theme,
                  step: '01',
                  title: 'Choose your savings plan',
                  subtitle: 'Start with the account type that fits your goal.',
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: InkWell(
                    onTap: _selectSavingsType,
                    borderRadius: BorderRadius.circular(16),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Change',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildSectionHeading(
                  theme,
                  step: '02',
                  title: 'Set your target',
                  subtitle:
                      'Give your goal a name and a clear amount to reach.',
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Goal details',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
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
                                      'Unavailable until backend terms are provided',
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
                        const SizedBox(height: 12),
                        Text(
                          'Interest terms and maturity projections are unavailable until provided by the backend.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
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

                _buildSectionHeading(
                  theme,
                  step: '03',
                  title: 'Review your plan',
                  subtitle:
                      'Check the details before creating your savings goal.',
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Savings Plan',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_nameController.text.trim().isEmpty &&
                          _targetController.text.trim().isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Your completed details will appear here.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacitySafe(0.6),
                            ),
                          ),
                        ),
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
                              'Unavailable',
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
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isFormValid && !_isSubmitting
                        ? () async {
                            if (!mounted) return;
                            final router = GoRouter.of(context);
                            final messenger = ScaffoldMessenger.maybeOf(
                              context,
                            );
                            final userId =
                                ref.read(authProvider).userId?.trim() ?? '';
                            if (userId.isEmpty) {
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Your session is incomplete. Please sign in again.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() => _isSubmitting = true);

                            try {
                              await ref
                                  .read(savingsServiceProvider)
                                  .createSavings(
                                    userId: userId,
                                    name: _nameController.text.trim(),
                                    targetAmount:
                                        double.tryParse(
                                          _targetController.text,
                                        ) ??
                                        0,
                                    autoSave: _autoSave,
                                  );

                              final newSavings = Savings(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                title: _nameController.text.trim(),
                                balance: 0,
                                target:
                                    double.tryParse(_targetController.text) ??
                                    0,
                                type: _selectedType,
                                interestRate: null,
                                maturityDate:
                                    _selectedType == SavingsType.fixedDeposit
                                    ? _maturityDate
                                    : null,
                              );

                              await SavingsStorage.addGoal(newSavings);
                              try {
                                await NotificationService.instance.addNotification(
                                  AppNotification(
                                    id: 'savings_created_${DateTime.now().millisecondsSinceEpoch}',
                                    title: 'Savings goal created',
                                    message:
                                        'Your savings goal “${newSavings.title}” is now ready to grow.',
                                    timestamp: DateTime.now(),
                                    type: AppNotificationType.savings,
                                    read: false,
                                  ),
                                );
                              } catch (error) {
                                debugPrint(
                                  'Savings goal notification failed: $error',
                                );
                              }

                              if (!mounted) return;

                              router.pushReplacementNamed(
                                'savings-success',
                                extra: newSavings,
                              );
                            } on AppException catch (error) {
                              if (!mounted) return;
                              setState(() => _isSubmitting = false);
                              messenger?.showSnackBar(
                                SnackBar(content: Text(error.message)),
                              );
                            } catch (_) {
                              if (!mounted) return;
                              setState(() => _isSubmitting = false);
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'We could not create this savings goal. Please try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: theme.colorScheme.primary.withOpacitySafe(
                        0.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text('Create ${_selectedType.label} Goal'),
                            ],
                          ),
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

  Widget _buildSummaryPill(
    ThemeData theme, {
    required String label,
    required IconData icon,
    Color? accent,
  }) {
    final resolvedAccent = accent ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: resolvedAccent.withOpacitySafe(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedAccent.withOpacitySafe(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: resolvedAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: resolvedAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    ThemeData theme, {
    required String number,
    required String label,
    required bool active,
  }) {
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacitySafe(0.38);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: theme.textTheme.labelMedium?.copyWith(
              color: active ? Colors.white : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading(
    ThemeData theme, {
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacitySafe(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            step,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
