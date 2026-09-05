import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AirtimePurchaseScreen extends StatefulWidget {
  const AirtimePurchaseScreen({super.key});

  @override
  State<AirtimePurchaseScreen> createState() => _AirtimePurchaseScreenState();
}

class _AirtimePurchaseScreenState extends State<AirtimePurchaseScreen> {
  static const List<String> _networks = [
    'MTN',
    'Vodafone',
    'Telecel',
    'AirtelTigo',
  ];

  static const List<int> _presetAmounts = [5, 10, 20, 50, 100];

  final TextEditingController _phoneController = TextEditingController(
    text: '024 123 4567',
  );
  final TextEditingController _amountController = TextEditingController(
    text: '10',
  );
  final TextEditingController _pinController = TextEditingController();

  String _selectedNetwork = _networks.first;
  int _currentStep = 0;
  bool _isProcessing = false;

  final List<String> _savedNumbers = [
    '024 123 4567',
    '020 987 6543',
    '055 456 7891',
  ];

  bool get _isPhoneValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 && digits.startsWith('0');
  }

  double get _selectedAmount {
    final parsed = double.tryParse(_amountController.text.replaceAll(',', '').trim());
    return parsed ?? 0;
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _isPhoneValid;
      case 1:
        return _selectedAmount > 0;
      case 2:
        return true;
      case 3:
        return _pinController.text.length >= 4;
      default:
        return true;
    }
  }

  String _getCurrentStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Network & Number';
      case 1:
        return 'Amount';
      case 2:
        return 'Review';
      case 3:
        return 'Enter PIN';
      case 4:
        return 'Processing';
      case 5:
        return 'Success';
      case 6:
        return 'Receipt';
      default:
        return 'Airtime';
    }
  }

  Future<void> _advance() async {
    if (!_canProceed) return;

    if (_currentStep == 3) {
      setState(() {
        _currentStep = 4;
        _isProcessing = true;
      });

      await Future<void>.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _currentStep = 5;
      });
      return;
    }

    if (_currentStep == 5) {
      setState(() => _currentStep = 6);
      return;
    }

    if (_currentStep < 6) {
      setState(() => _currentStep += 1);
    }
  }

  void _selectSavedNumber(String number) {
    _phoneController.text = number;
    setState(() {});
  }

  void _applyPresetAmount(int value) {
    _amountController.text = value.toString();
    setState(() {});
  }

  void _goBack() {
    if (_currentStep == 0) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/payments-hub');
      }
      return;
    }

    setState(() => _currentStep -= 1);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget _buildStepHeader() {
    final steps = ['1', '2', '3', '4', '5', '6', '7'];

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(steps.length, (index) {
                final isActive = index == _currentStep;
                final isComplete = index < _currentStep;
                final label = <String>[
                  'Network',
                  'Amount',
                  'Review',
                  'PIN',
                  'Processing',
                  'Success',
                  'Receipt',
                ][index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF2E8B57)
                              : isComplete
                                  ? const Color(0xFF0F8B5B)
                                  : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF2E8B57)
                                : isComplete
                                    ? const Color(0xFF0F8B5B)
                                    : const Color(0xFFE2E6E4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          steps[index],
                          style: TextStyle(
                            color: isActive || isComplete
                                ? Colors.white
                                : const Color(0xFF5A625D),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: isActive || isComplete
                              ? const Color(0xFF1E312A)
                              : Colors.grey[500],
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildNetworkStep() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EAE6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Network',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _networks.map((network) {
                  final isSelected = network == _selectedNetwork;
                  return ChoiceChip(
                    label: Text(network),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedNetwork = network),
                    selectedColor: const Color(0xFF2E8B57),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1F2A25),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF2E8B57)
                          : const Color(0xFFE3EAE6),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone number',
            hintText: '024 123 4567',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE3EAE6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 1.5),
            ),
            prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF2E8B57)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: Text(
            'Saved numbers',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._savedNumbers.map(
          (number) => GestureDetector(
            onTap: () => _selectSavedNumber(number),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3EAE6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Color(0xFF2E8B57)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      number,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_phoneController.text == number)
                    const Icon(Icons.check_circle, color: Color(0xFF2E8B57)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How much airtime do you want?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: '10',
            prefixText: 'GH₵ ',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE3EAE6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presetAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;
            return ChoiceChip(
              label: Text('GH₵ $amount'),
              selected: isSelected,
              onSelected: (_) => _applyPresetAmount(amount),
              selectedColor: const Color(0xFF2E8B57),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1F2A25),
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF2E8B57)
                    : const Color(0xFFE3EAE6),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final amount = _selectedAmount;
    const fee = 0.0;
    final total = amount + fee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewRow(label: 'Network', value: _selectedNetwork),
          const SizedBox(height: 12),
          _ReviewRow(label: 'Phone number', value: _phoneController.text),
          const SizedBox(height: 12),
          _ReviewRow(label: 'Amount', value: 'GH₵ ${amount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _ReviewRow(label: 'Fee', value: 'GH₵ ${fee.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _ReviewRow(
            label: 'Total',
            value: 'GH₵ ${total.toStringAsFixed(2)}',
            isStrong: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5EE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_outline_rounded, size: 32, color: Color(0xFF2E8B57)),
        ),
        const SizedBox(height: 18),
        Text(
          'Enter your PIN',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please authorize this airtime purchase.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFE3EAE6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E8B57)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Processing your airtime purchase...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we complete the transaction.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5A625D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAE6)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 42, color: Color(0xFF2E8B57)),
          ),
          const SizedBox(height: 18),
          Text(
            'Airtime Purchase Successful!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your airtime of GH₵ ${_selectedAmount.toStringAsFixed(2)} has been processed successfully.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5A625D),
            ),
          ),
          const SizedBox(height: 18),
          _InfoRow(label: 'Network', value: _selectedNetwork),
          const SizedBox(height: 8),
          _InfoRow(label: 'Phone', value: _phoneController.text),
          const SizedBox(height: 8),
          _InfoRow(label: 'Reference', value: 'ADEPA-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}'),
        ],
      ),
    );
  }

  Widget _buildReceiptStep() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2E8B57)),
              ),
              const SizedBox(width: 12),
              Text(
                'Airtime Receipt',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Network', value: _selectedNetwork),
          const SizedBox(height: 10),
          _InfoRow(label: 'Phone Number', value: _phoneController.text),
          const SizedBox(height: 10),
          _InfoRow(label: 'Amount', value: 'GH₵ ${_selectedAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _InfoRow(label: 'Date', value: DateTime.now().toString().substring(0, 16)),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Reference',
            value: 'ADEPA-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download Receipt'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E8B57),
                side: const BorderSide(color: Color(0xFF2E8B57)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepsContent = <Widget>[
      _buildNetworkStep(),
      _buildAmountStep(),
      _buildReviewStep(),
      _buildPinStep(),
      _buildProcessingStep(),
      _buildSuccessStep(),
      _buildReceiptStep(),
    ];

    final isLastStep = _currentStep == 6;
    final infoCards = [
      _InfoPillCard(
        icon: Icons.save_rounded,
        title: 'Save time',
        subtitle: 'Save your frequently used numbers for faster airtime purchases.',
      ),
      _InfoPillCard(
        icon: Icons.warning_amber_rounded,
        title: 'Important notes',
        subtitle: 'Airtime is delivered instantly to the selected number.',
      ),
      _InfoPillCard(
        icon: Icons.help_center_rounded,
        title: 'Need help?',
        subtitle: 'For any issues or failed transactions, contact our support team.',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      'Airtime Purchase',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C1F1E),
                      ),
                    ),
                  ),
                  Text(
                    _getCurrentStepTitle(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF2E8B57),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStepHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey<int>(_currentStep),
                    child: stepsContent[_currentStep],
                  ),
                ),
              ),
              if (_currentStep < 6) ...[
                const SizedBox(height: 18),
                Column(
                  children: infoCards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(width: double.infinity, child: card),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              if (_currentStep < 4 || _currentStep == 5)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canProceed && !_isProcessing ? _advance : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _currentStep == 5 ? 'View Receipt' : _currentStep == 3 ? 'Confirm Purchase' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else if (isLastStep)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/payments-hub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B57),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStrong;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF1C1F1E),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5A625D),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1F1E),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPillCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoPillCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
