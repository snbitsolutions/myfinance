import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/modern_input.dart';
import 'savings_model.dart';

class CreateSavingsScreen extends StatefulWidget {
  const CreateSavingsScreen({super.key});

  @override
  State<CreateSavingsScreen> createState() => _CreateSavingsScreenState();
}

class _CreateSavingsScreenState extends State<CreateSavingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  late SavingsType _selectedType;
  bool _autoSave = false;
  DateTime? _maturityDate;

  @override
  void initState() {
    super.initState();
    _selectedType = SavingsType.memberSaving;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Create Savings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Savings Type Selection
            Text(
              'Savings Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: SavingsType.values.map((type) {
                final isSelected = type == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacitySafe(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          size: 32,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type.label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModernInput(
                    label: 'Savings Goal',
                    hintText: 'e.g., Emergency Fund',
                    controller: _nameController,
                    prefixIcon: Icons.savings,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  ModernInput(
                    label: 'Target Amount',
                    hintText: 'e.g., 2000',
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    prefixText: 'GH₵ ',
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_selectedType == SavingsType.fixedDeposit) ...[
                    const SizedBox(height: 16),
                    ModernInput(
                      label: 'Interest Rate (%)',
                      hintText: 'e.g., 5.5',
                      controller: _interestController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.percent,
                      onChanged: (_) => setState(() {}),
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
                          setState(() => _maturityDate = selected);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacitySafe(
                              0.3,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maturity Date',
                                  style: theme.textTheme.labelSmall?.copyWith(
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
                              ],
                            ),
                          ],
                        ),
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
                          color: theme.colorScheme.primary.withOpacitySafe(0.2),
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
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Automatically save amounts monthly',
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
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _nameController.text.trim().isNotEmpty &&
                        (_targetController.text.trim().isNotEmpty)
                    ? () {
                        // Create the savings object
                        final newSavings = Savings(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: _nameController.text.trim(),
                          balance: 0, // Start with zero balance
                          target: double.tryParse(_targetController.text) ?? 0,
                          type: _selectedType,
                          interestRate:
                              _selectedType == SavingsType.fixedDeposit
                              ? double.tryParse(_interestController.text)
                              : null,
                          maturityDate:
                              _selectedType == SavingsType.fixedDeposit
                              ? _maturityDate
                              : null,
                        );

                        // Return the new savings goal
                        context.pop(newSavings);
                      }
                    : null,
                child: const Text('Create Savings Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
