import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BillsPaymentScreen extends StatefulWidget {
  const BillsPaymentScreen({super.key});

  @override
  State<BillsPaymentScreen> createState() => _BillsPaymentScreenState();
}

class _BillsPaymentScreenState extends State<BillsPaymentScreen> {
  final List<String> _billers = [
    'ECG',
    'Ghana Water',
    'DSTV',
    'GOtv',
    'NHIS',
  ];

  final List<_StepMeta> _steps = const [
    _StepMeta(title: 'Select Biller', subtitle: 'Choose the bill you want to pay'),
    _StepMeta(title: 'Enter Details', subtitle: 'Add your meter or account number'),
    _StepMeta(title: 'Verify', subtitle: 'Confirm your customer details'),
    _StepMeta(title: 'Amount', subtitle: 'Enter the amount to pay'),
    _StepMeta(title: 'Review', subtitle: 'Check payment details'),
    _StepMeta(title: 'PIN', subtitle: 'Authorize payment'),
    _StepMeta(title: 'Success', subtitle: 'Payment complete'),
  ];

  int _currentStep = 0;
  String _selectedBiller = 'ECG';
  final TextEditingController _meterController =
      TextEditingController(text: '1234567890');
  final TextEditingController _amountController =
      TextEditingController(text: '200');
  final TextEditingController _pinController = TextEditingController();

  double get _amountValue => double.tryParse(_amountController.text) ?? 0;

  bool get _canContinue {
    if (_currentStep == 0) return true;
    if (_currentStep == 1) return _meterController.text.trim().isNotEmpty;
    if (_currentStep == 3) return _amountValue > 0;
    if (_currentStep == 5) return _pinController.text.trim().length >= 4;
    return true;
  }

  String _iconForBiller(String biller) {
    switch (biller) {
      case 'ECG':
        return '⚡';
      case 'Ghana Water':
        return '💧';
      case 'DSTV':
        return '📺';
      case 'GOtv':
        return '📡';
      default:
        return '🏥';
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      return;
    }

    context.go('/home');
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
    _amountController.dispose();
    _pinController.dispose();
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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pay Bills',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C1F1E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        child: Text(
                          _iconForBiller(_selectedBiller),
                          style: const TextStyle(fontSize: 20),
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
                            _currentStep == 3
                                ? 'Amount ready for payment'
                                : _currentStep > 3
                                    ? 'Review and confirm payment'
                                    : 'Bill details in progress',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5A625D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'GH₵ ${_amountValue.toStringAsFixed(2)}',
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
                  child: Container(
                    key: ValueKey<int>(_currentStep),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8EFEA)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0C291A).withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _buildStepContent(theme, currentTitle, currentSubtitle),
                  ),
                ),
              ),
              if (_currentStep < _steps.length - 1) ...[
                const SizedBox(height: 18),
                Column(
                  children: [
                    _InfoAssistCard(
                      icon: Icons.flash_on_rounded,
                      title: 'Save time',
                      subtitle: 'Use preset amounts and saved billers for faster payments.',
                    ),
                    const SizedBox(height: 10),
                    _InfoAssistCard(
                      icon: Icons.info_outline_rounded,
                      title: 'Important notes',
                      subtitle: 'Payments are processed instantly once confirmed.',
                    ),
                    const SizedBox(height: 10),
                    _InfoAssistCard(
                      icon: Icons.help_center_rounded,
                      title: 'Need help?',
                      subtitle: 'Contact support if the biller or payment details are wrong.',
                    ),
                  ],
                ),
              ],
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
                        _currentStep == _steps.length - 1 ? 'Done' : 'Continue',
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
          selectedBiller: _selectedBiller,
        );
      case 2:
        return _VerificationPage(
          biller: _selectedBiller,
          meterNumber: _meterController.text,
        );
      case 3:
        return _AmountPage(
          amountController: _amountController,
          selectedBiller: _selectedBiller,
        );
      case 4:
        return _ReviewPage(
          biller: _selectedBiller,
          amount: _amountValue,
        );
      case 5:
        return _AuthorizationPage(
          pinController: _pinController,
          amount: _amountValue,
          biller: _selectedBiller,
        );
      case 6:
        return _SuccessPage(
          biller: _selectedBiller,
          amount: _amountValue,
          reference: 'ADEPA-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 11)}',
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
              color: isActive ? const Color(0xFF2E8B57) : const Color(0xFFE4E9E6),
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
                          color: const Color(0xFF2E8B57).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _iconForBiller(biller),
                            style: const TextStyle(fontSize: 22),
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

  String _iconForBiller(String biller) {
    switch (biller) {
      case 'ECG':
        return '⚡';
      case 'Ghana Water':
        return '💧';
      case 'DSTV':
        return '📺';
      case 'GOtv':
        return '📡';
      default:
        return '🏥';
    }
  }

  String _subtitleForBiller(String biller) {
    switch (biller) {
      case 'ECG':
        return 'Electricity Company of Ghana';
      case 'Ghana Water':
        return 'Water bill payment';
      case 'DSTV':
        return 'Satellite TV subscription';
      case 'GOtv':
        return 'Cable TV subscription';
      default:
        return 'National Health Insurance';
    }
  }
}

class _CustomerDetailsPage extends StatelessWidget {
  final TextEditingController meterController;
  final String selectedBiller;

  const _CustomerDetailsPage({
    required this.meterController,
    required this.selectedBiller,
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
          keyboardType: TextInputType.name,
          decoration: InputDecoration(
            labelText: 'Customer Name',
            hintText: 'John Mensah',
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

  const _VerificationPage({required this.biller, required this.meterNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Customer',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E8B57)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Customer found successfully for $biller',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SummaryRow(label: 'Biller', value: biller),
        _SummaryRow(label: 'Meter Number', value: meterNumber),
        _SummaryRow(label: 'Customer', value: 'John Mensah'),
        _SummaryRow(label: 'Address', value: 'Agbogba, Accra'),
      ],
    );
  }
}

class _AmountPage extends StatelessWidget {
  final TextEditingController amountController;
  final String selectedBiller;

  const _AmountPage({
    required this.amountController,
    required this.selectedBiller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Amount',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How much do you want to pay to $selectedBiller?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: 'GH₵ ',
            labelText: 'Amount',
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
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['50', '100', '200', '500'].map((value) {
            return GestureDetector(
              onTap: () => amountController.text = value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E5E2)),
                ),
                child: Text('GH₵ $value'),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ReviewPage extends StatelessWidget {
  final String biller;
  final double amount;

  const _ReviewPage({required this.biller, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fee = amount * 0.025;
    final total = amount + fee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Payment',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        _SummaryRow(label: 'Biller', value: biller),
        _SummaryRow(label: 'Amount', value: 'GH₵ ${amount.toStringAsFixed(2)}'),
        _SummaryRow(label: 'Fee', value: 'GH₵ ${fee.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2E8B57).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                'GH₵ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E8B57),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthorizationPage extends StatelessWidget {
  final TextEditingController pinController;
  final double amount;
  final String biller;

  const _AuthorizationPage({
    required this.pinController,
    required this.amount,
    required this.biller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authorize Payment',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your 4-digit PIN to authorize this payment of GH₵ ${amount.toStringAsFixed(2)} to $biller.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: InputDecoration(
            labelText: 'PIN',
            counterText: '',
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

class _SuccessPage extends StatelessWidget {
  final String biller;
  final double amount;
  final String reference;

  const _SuccessPage({
    required this.biller,
    required this.amount,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 38,
            color: Color(0xFF2E8B57),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Payment Successful',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your payment to $biller was processed successfully.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Biller', value: biller),
              _SummaryRow(label: 'Amount', value: 'GH₵ ${amount.toStringAsFixed(2)}'),
              _SummaryRow(label: 'Reference', value: reference),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoAssistCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoAssistCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1EAE3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF153524).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E8B57), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2B26),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5A625D),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5A625D),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1C1F1E),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
