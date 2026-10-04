import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';

class BillsPaymentScreen extends StatefulWidget {
  const BillsPaymentScreen({super.key});

  @override
  State<BillsPaymentScreen> createState() => _BillsPaymentScreenState();
}

class _BillsPaymentScreenState extends State<BillsPaymentScreen> {
  final List<String> _billers = ['ECG', 'GWCL', 'DSTV'];

  final List<_StepMeta> _steps = const [
    _StepMeta(
      title: 'Select Biller',
      subtitle: 'Choose the bill you want to pay',
    ),
    _StepMeta(
      title: 'Enter Details',
      subtitle: 'Add your meter or account number',
    ),
    _StepMeta(title: 'Verify Customer', subtitle: 'Details are not verified'),
    _StepMeta(title: 'Amount', subtitle: 'Enter amount to pay'),
    _StepMeta(title: 'Review', subtitle: 'Review the payment details'),
    _StepMeta(
      title: 'Unavailable',
      subtitle: 'Payment authorization is not connected',
    ),
  ];

  int _currentStep = 0;
  String _selectedBiller = 'ECG';
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  double get _amountValue =>
      double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;

  bool get _canContinue {
    if (_currentStep == 0) return true;
    if (_currentStep == 1) return _meterController.text.trim().isNotEmpty;
    if (_currentStep == 3) return _amountValue > 0;
    if (_currentStep == 5) return false;
    return true;
  }

  String _logoForBiller(String biller) {
    switch (biller) {
      case 'ECG':
        return 'images/ecg_logo.jpg';
      case 'GWCL':
        return 'images/gwcl_logo.png';
      case 'DSTV':
        return 'images/dstv_logo.webp';
      default:
        return 'images/ecg_logo.jpg';
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      return;
    }

  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _meterController.dispose();
    _customerNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTitle = _steps[_currentStep].title;
    final currentSubtitle = _steps[_currentStep].subtitle;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _previousStep,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pay Bills',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCAE3D4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            _logoForBiller(_selectedBiller),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedBiller,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1C1F1E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentStep == 5
                                ? 'Payment service unavailable'
                                : 'Bill details in progress',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5A625D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _currentStep == 5
                            ? 'Unavailable'
                            : 'No payment yet',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E8B57),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _StepProgress(currentStep: _currentStep, total: _steps.length),
              const SizedBox(height: 18),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: AppCard(
                    key: ValueKey<int>(_currentStep),
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(18),
                    child: _buildStepContent(
                      theme,
                      currentTitle,
                      currentSubtitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1C1F1E),
                          side: const BorderSide(color: Color(0xFFE0E5E2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canContinue ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E8B57),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep == _steps.length - 1 ? 'Unavailable' : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(
    ThemeData theme,
    String currentTitle,
    String currentSubtitle,
  ) {
    switch (_currentStep) {
      case 0:
        return _SelectBillerPage(
          billers: _billers,
          selectedBiller: _selectedBiller,
          onSelect: (value) => setState(() => _selectedBiller = value),
        );
      case 1:
        return _CustomerDetailsPage(
          meterController: _meterController,
          customerNameController: _customerNameController,
          selectedBiller: _selectedBiller,
          onChanged: () => setState(() {}),
        );
      case 2:
        return _VerificationPage(
          biller: _selectedBiller,
          meterNumber: _meterController.text,
          customerName: _customerNameController.text,
        );
      case 3:
        return _AmountPage(
          amountController: _amountController,
          biller: _selectedBiller,
          onChanged: () => setState(() {}),
        );
      case 4:
        return _ReviewPage(
          biller: _selectedBiller,
          meterNumber: _meterController.text,
          amount: _amountValue,
        );
      case 5:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 44, color: Color(0xFFB86A14)),
            SizedBox(height: 12),
            Text(
              'Bill payment authorization is unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'No bill payment service is connected. No PIN was collected and no payment has been made.',
              textAlign: TextAlign.center,
            ),
          ],
        );
      default:
        return Column(
          children: [
            Text(currentTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(currentSubtitle, style: theme.textTheme.bodyMedium),
          ],
        );
    }
  }
}

class _StepMeta {
  final String title;
  final String subtitle;

  const _StepMeta({required this.title, required this.subtitle});
}

class _StepProgress extends StatelessWidget {
  final int currentStep;
  final int total;

  const _StepProgress({required this.currentStep, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF2E8B57)
                  : const Color(0xFFE4E9E6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _SelectBillerPage extends StatelessWidget {
  final List<String> billers;
  final String selectedBiller;
  final ValueChanged<String> onSelect;

  const _SelectBillerPage({
    required this.billers,
    required this.selectedBiller,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Biller',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1C1F1E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the biller you want to pay.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: billers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final biller = billers[index];
              final isSelected = biller == selectedBiller;
              return GestureDetector(
                onTap: () => onSelect(biller),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEAF5EE) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFB9DCCB)
                          : const Color(0xFFE1E7E4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2E8B57,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              _logoForBiller(biller),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              biller,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitleForBiller(biller),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF5A625D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF2E8B57),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _logoForBiller(String biller) {
    switch (biller) {
      case 'ECG':
        return 'images/ecg_logo.jpg';
      case 'GWCL':
        return 'images/gwcl_logo.png';
      case 'DSTV':
        return 'images/dstv_logo.webp';
      default:
        return 'images/ecg_logo.jpg';
    }
  }

  String _subtitleForBiller(String biller) {
    switch (biller) {
      case 'ECG':
        return 'Electricity Company of Ghana';
      case 'GWCL':
        return 'Ghana Water Company Limited';
      case 'DSTV':
        return 'Satellite TV subscription';
      default:
        return 'National Health Insurance';
    }
  }
}

class _CustomerDetailsPage extends StatelessWidget {
  final TextEditingController meterController;
  final TextEditingController customerNameController;
  final String selectedBiller;
  final VoidCallback onChanged;

  const _CustomerDetailsPage({
    required this.meterController,
    required this.customerNameController,
    required this.selectedBiller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Details',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your customer information for $selectedBiller.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: meterController,
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: 'Meter / Account Number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E5E2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E5E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E8B57)),
            ),
            filled: true,
            fillColor: const Color(0xFFF7F8F7),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: customerNameController,
          keyboardType: TextInputType.name,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: 'Customer Name',
            hintText: 'Enter customer name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E5E2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E5E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E8B57)),
            ),
            filled: true,
            fillColor: const Color(0xFFF7F8F7),
          ),
        ),
      ],
    );
  }
}

class _VerificationPage extends StatelessWidget {
  final String biller;
  final String meterNumber;
  final String customerName;

  const _VerificationPage({
    required this.biller,
    required this.meterNumber,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review customer details', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        _BillDetail(label: 'Biller', value: biller),
        _BillDetail(label: 'Meter / account', value: meterNumber),
        _BillDetail(
          label: 'Customer name entered',
          value: customerName.trim().isEmpty ? 'Not provided' : customerName,
        ),
        const SizedBox(height: 12),
        const Text(
          'These details have not been verified with the biller. The next screens are a preview only; no payment can be submitted.',
        ),
      ],
    );
  }
}

class _AmountPage extends StatelessWidget {
  final TextEditingController amountController;
  final String biller;
  final VoidCallback onChanged;

  const _AmountPage({
    required this.amountController,
    required this.biller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment amount', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Amount for $biller. This is a preview only.'),
        const SizedBox(height: 16),
        TextField(
          controller: amountController,
          onChanged: (_) => onChanged(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'GH₵ ',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class _ReviewPage extends StatelessWidget {
  final String biller;
  final String meterNumber;
  final double amount;

  const _ReviewPage({
    required this.biller,
    required this.meterNumber,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review payment', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _BillDetail(label: 'Biller', value: biller),
        _BillDetail(label: 'Meter / account', value: meterNumber),
        _BillDetail(label: 'Amount', value: 'GH₵ ${amount.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        const Text('No payment has been initiated.'),
      ],
    );
  }
}

class _BillDetail extends StatelessWidget {
  final String label;
  final String value;

  const _BillDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
