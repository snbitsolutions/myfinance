import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_card.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/modern_input.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/secure_auth_storage.dart';
import '../../core/utils/receipt_clipboard.dart';

class MobilePurchaseScreen extends ConsumerStatefulWidget {
  const MobilePurchaseScreen({super.key, this.isData = false});

  final bool isData;

  @override
  ConsumerState<MobilePurchaseScreen> createState() =>
      _MobilePurchaseScreenState();
}

class _MobilePurchaseScreenState extends ConsumerState<MobilePurchaseScreen> {
  static const List<String> _networks = ['MTN', 'Telecel', 'AirtelTigo'];
  static const Duration _statusCheckInterval = Duration(seconds: 5);
  static const int _maxAutomaticStatusChecks = 24;

  static const List<int> _presetAmounts = [5, 10, 20, 50, 100];
  static const String _airtimeProductId = '51437';
  static const String _dataProductId = '59656';

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  String _selectedNetwork = _networks.first;
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _isPending = false;
  bool _isFailed = false;
  bool _isConfirmed = false;
  String? _transactionReference;
  DateTime? _submittedAt;
  String? _submissionError;
  Timer? _statusCheckTimer;
  int _automaticStatusChecks = 0;
  bool _isCheckingStatus = false;
  String? _statusCheckError;

  void _startStatusPolling() {
    if (!_isPending) return;
    _statusCheckTimer?.cancel();
    _automaticStatusChecks = 0;
    _checkPurchaseStatus();
    _statusCheckTimer = Timer.periodic(_statusCheckInterval, (_) {
      if (_automaticStatusChecks >= _maxAutomaticStatusChecks) {
        _statusCheckTimer?.cancel();
        if (mounted) {
          setState(() {
            _statusCheckError =
                'Confirmation is still pending. Check transaction history or try again.';
          });
        }
        return;
      }
      _automaticStatusChecks++;
      _checkPurchaseStatus();
    });
  }

  Future<void> _checkPurchaseStatus() async {
    if (!mounted ||
        !_isPending ||
        _isCheckingStatus ||
        ((_transactionReference ?? '').trim().isEmpty &&
            _submittedAt == null)) {
      return;
    }
    _isCheckingStatus = true;
    if (mounted) {
      setState(() {
        _statusCheckError = null;
      });
    }
    try {
      ref.invalidate(transactionsProvider);
      final transactions = await ref.read(transactionsProvider.future);
      if (!mounted) return;

      final reference = _transactionReference?.trim().toLowerCase();
      Map<String, dynamic>? matchingTransaction;
      if (reference != null && reference.isNotEmpty) {
        matchingTransaction = transactions.where((transaction) {
          for (final key in const [
            'transaction_id',
            'transactionId',
            'reference',
            'trans_id',
            'id',
            'external_transaction_id',
            'client_reference',
          ]) {
            final transactionReference = transaction[key]
                ?.toString()
                .trim()
                .toLowerCase();
            if (transactionReference == reference) return true;
          }
          return false;
        }).firstOrNull;
      }

      matchingTransaction ??= transactions.where((transaction) {
        final amount = switch (transaction['amount']) {
          num value => value.toDouble(),
          String value => double.tryParse(value.replaceAll(',', '').trim()),
          _ => null,
        };
        if (amount == null || (amount - _selectedAmount).abs() > 0.001) {
          return false;
        }

        final description =
            '${transaction['description'] ?? ''} ${transaction['narration'] ?? ''}'
                .toLowerCase();
        final type = '${transaction['type'] ?? ''}'.toLowerCase();
        final looksLikePurchase =
            description.contains(_serviceName.toLowerCase()) ||
            description.contains('airtime') ||
            description.contains('data') ||
            description.contains('edeposit') ||
            description.contains('mobile') ||
            type.contains('purchase');
        if (!looksLikePurchase) return false;

        final dateValue =
            transaction['date'] ?? transaction['transaction_date'];
        final transactionDate = DateTime.tryParse(dateValue?.toString() ?? '');
        return _submittedAt == null ||
            transactionDate == null ||
            !transactionDate.isBefore(
              _submittedAt!.subtract(const Duration(minutes: 10)),
            );
      }).firstOrNull;
      if (matchingTransaction == null) return;

      String? status;
      for (final key in const [
        'status',
        'state',
        'transaction_status',
        'payment_status',
      ]) {
        final value = matchingTransaction[key]?.toString().trim().toLowerCase();
        if (value != null && value.isNotEmpty) {
          status = value;
          break;
        }
      }

      if (const {
        '1',
        'complete',
        'completed',
        'confirmed',
        'done',
        'paid',
        'success',
        'successful',
        'approved',
        'settled',
      }.contains(status)) {
        _statusCheckTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isPending = false;
          _isFailed = false;
          _isConfirmed = true;
        });
        await refreshMemberAccountData(ref);
      } else if (const {
        '0',
        'cancelled',
        'canceled',
        'declined',
        'denied',
        'error',
        'expired',
        'failed',
        'failure',
        'rejected',
      }.contains(status)) {
        _statusCheckTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isPending = false;
          _isFailed = true;
          _isConfirmed = false;
        });
      }
    } catch (error) {
      debugPrint('Mobile purchase status check failed: $error');
      if (mounted) {
        setState(() {
          _statusCheckError =
              'We could not check the status just now. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      } else {
        _isCheckingStatus = false;
      }
    }
  }

  bool get _isPhoneValid {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 && digits.startsWith('0');
  }

  double get _selectedAmount {
    final parsed = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    return parsed ?? 0;
  }

  double? _readAvailableBalance(dynamic value) {
    if (value is num) {
      return value.isFinite && value >= 0 ? value.toDouble() : null;
    }
    final normalized = value?.toString().replaceAll(',', '').trim();
    final parsed = normalized == null ? null : double.tryParse(normalized);
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _isPhoneValid;
      case 1:
        return _selectedAmount > 0;
      case 2:
        return RegExp(r'^\d{4}$').hasMatch(_pinController.text);
      case 3:
        return false;
      case 4:
        return true;
      case 5:
        return false;
      default:
        return true;
    }
  }

  String get _serviceName => widget.isData ? 'Data' : 'Airtime';
  String get _serviceTitle => '$_serviceName Purchase';

  Future<void> _advance() async {
    if (!_canProceed) return;

    if (_currentStep == 2) {
      final pin = _pinController.text.trim();
      setState(() {
        _isProcessing = true;
        _submissionError = null;
        _currentStep = 3;
      });
      try {
        ref.invalidate(userProfileProvider);
        final profile = await ref.read(userProfileProvider.future);
        final phone = _toInternationalPhone(_phoneController.text);
        final channel = _selectedNetwork.toLowerCase() == 'mtn'
            ? 'mtn-gh'
            : '${_selectedNetwork.toLowerCase()}-gh';
        final username = (profile['name'] ?? '').toString().trim();
        if (username.isEmpty) {
          throw StateError(
            'Your profile is missing a customer name. Update your profile before purchasing.',
          );
        }

        final availableBalance = _readAvailableBalance(profile['balance']);
        if (availableBalance != null && _selectedAmount > availableBalance) {
          throw StateError(
            'Insufficient balance. Your available balance is GH₵ '
            '${availableBalance.toStringAsFixed(2)}.',
          );
        }

        await SecureAuthStorage.instance.verifyPin(pin);
        _pinController.clear();
        final paymentService = ref.read(paymentServiceProvider);
        final Map<String, dynamic> result;
        if (widget.isData) {
          result = await paymentService.buyDataBundle(
            phoneNumber: phone,
            channel: channel,
            amount: _selectedAmount,
            username: username,
            productId: _dataProductId,
            pin: pin,
          );
        } else {
          result = await paymentService.buyAirtime(
            phoneNumber: phone,
            channel: channel,
            amount: _selectedAmount,
            username: username,
            productId: _airtimeProductId,
            pin: pin,
          );
        }
        if (!mounted) return;
        _isPending = result['is_pending'] == true;
        _isConfirmed = !_isPending;
        _isFailed = false;
        _transactionReference =
            (result['reference'] ?? result['transaction_id'])?.toString();
        _submittedAt = DateTime.now();
        await refreshMemberAccountData(ref);
        if (!mounted) return;
        setState(() => _currentStep = 4);
        _startStatusPolling();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$_serviceName request initiated${_transactionReference == null ? '' : ' ($_transactionReference)'}.',
            ),
          ),
        );
      } on AppException catch (error) {
        if (!mounted) return;
        setState(() {
          _submissionError = error.message;
          _currentStep = 2;
        });
      } on StateError catch (error) {
        if (!mounted) return;
        setState(() {
          _submissionError = error.message;
          _currentStep = 2;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _submissionError =
              'Unable to process the $_serviceName request. Check transaction history before trying again.';
          _currentStep = 2;
        });
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
      return;
    }

    if (_currentStep == 4) {
      setState(() => _currentStep = 5);
      return;
    }

    if (_currentStep < 5) {
      setState(() => _currentStep += 1);
    }
  }

  String _toInternationalPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return '233${digits.substring(1)}';
    if (digits.startsWith('233')) return digits;
    return digits;
  }

  void _applyPresetAmount(int value) {
    _amountController.text = value.toString();
    setState(() {
      _submissionError = null;
    });
  }

  void _goBack() {
    if (_isProcessing) return;
    if (_currentStep >= 4) {
      context.go('/payments-hub');
      return;
    }
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
    _statusCheckTimer?.cancel();
    _phoneController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget _buildNetworkStep() {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Network',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _networks.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 48,
                ),
                itemBuilder: (context, index) {
                  final network = _networks[index];
                  final isSelected = network == _selectedNetwork;

                  return Material(
                    color: isSelected ? const Color(0xFF2E8B57) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedNetwork = network),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2E8B57)
                                : const Color(0xFFE3EAE6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF5A625D),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                network,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1F2A25),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ModernInput(
          controller: _phoneController,
          keyboardType: TextInputType.number,
          label: 'Phone number',
          hintText: 'e.g. 024 123 4567',
          prefixIcon: Icons.phone_iphone_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          helperText: 'Enter a 10-digit Ghana number starting with 0.',
          errorText: _phoneController.text.length == 10 && !_isPhoneValid
              ? 'Enter a valid number starting with 0.'
              : null,
          onChanged: (_) => setState(() {
            _submissionError = null;
          }),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How much $_serviceName do you want?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        ModernInput(
          controller: _amountController,
          keyboardType: TextInputType.number,
          label: 'Amount',
          hintText: 'Enter an amount',
          prefixText: 'GH₵ ',
          onChanged: (_) => setState(() {
            _submissionError = null;
          }),
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewRow(label: 'Network', value: _selectedNetwork),
          const SizedBox(height: 12),
          _ReviewRow(label: 'Phone number', value: _phoneController.text),
          const SizedBox(height: 12),
          _ReviewRow(
            label: 'Amount',
            value: 'GH₵ ${amount.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _ReviewRow(
            label: 'Total',
            value: 'GH₵ ${amount.toStringAsFixed(2)}',
            isStrong: true,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your 4-digit mobile banking PIN to authorize this purchase.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5A625D)),
          ),
          const SizedBox(height: 10),
          ModernInput(
            controller: _pinController,
            label: 'Mobile banking PIN',
            hintText: '4-digit PIN',
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (_) => setState(() {
              _submissionError = null;
            }),
          ),
          if (_submissionError case final error?) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
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
            'Processing your $_serviceName purchase...',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we complete the transaction.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A625D)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    final title = _isFailed
        ? '$_serviceTitle Failed'
        : _isConfirmed
        ? '$_serviceTitle Successful'
        : _isPending
        ? '$_serviceTitle Pending'
        : '$_serviceTitle request initiated';
    final message = _isFailed
        ? 'The provider reported that the purchase failed.'
        : _isConfirmed
        ? 'The provider confirmed your purchase.'
        : _isPending
        ? 'Your request was accepted and is awaiting confirmation.'
        : 'The request was sent. The provider has not confirmed completion.';
    final icon = _isPending
        ? Icons.hourglass_top_rounded
        : _isConfirmed
        ? Icons.check_circle_outline_rounded
        : Icons.info_outline_rounded;
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
            child: Icon(icon, size: 42, color: Color(0xFF2E8B57)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A625D)),
          ),
          if (_isPending) ...[
            const SizedBox(height: 8),
            if (_statusCheckError case final error?)
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            TextButton.icon(
              onPressed: _isCheckingStatus ? null : _checkPurchaseStatus,
              icon: _isCheckingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                _isCheckingStatus ? 'Checking status…' : 'Check status now',
              ),
            ),
          ],
          const SizedBox(height: 18),
          _InfoRow(label: 'Network', value: _selectedNetwork),
          const SizedBox(height: 8),
          _InfoRow(label: 'Phone', value: _phoneController.text),
          const SizedBox(height: 8),
          _InfoRow(label: 'Reference', value: _transactionReference ?? '—'),
        ],
      ),
    );
  }

  Widget _buildReceiptStep() {
    final status = _isFailed
        ? 'Failed'
        : _isPending
        ? 'Pending'
        : 'Provider reported completion';
    final receiptText = [
      'ADEPA - $_serviceTitle Receipt',
      'Status: $status',
      'Network: $_selectedNetwork',
      'Phone: ${_phoneController.text}',
      'Amount: GH₵ ${_selectedAmount.toStringAsFixed(2)}',
      'Date: ${_submittedAt?.toIso8601String() ?? '—'}',
      'Reference: ${_transactionReference ?? '—'}',
    ].join('\n');

    return AppCard(
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
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF2E8B57),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_serviceTitle Receipt',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Network', value: _selectedNetwork),
          const SizedBox(height: 10),
          _InfoRow(label: 'Phone Number', value: _phoneController.text),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Amount',
            value: 'GH₵ ${_selectedAmount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Date',
            value: _submittedAt?.toLocal().toString() ?? '—',
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Reference', value: _transactionReference ?? '—'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  copyReceiptToClipboard(context, text: receiptText),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy receipt'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E8B57),
                side: const BorderSide(color: Color(0xFF2E8B57)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
      _buildProcessingStep(),
      _buildSuccessStep(),
      _buildReceiptStep(),
    ];

    final isLastStep = _currentStep == 5;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: _goBack,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 22,
                            ),
                            color: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        Text(
                          _serviceTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: SizedBox(
                          key: ValueKey<int>(_currentStep),
                          width: double.infinity,
                          child: stepsContent[_currentStep],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_currentStep != 3 && !isLastStep)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canProceed && !_isProcessing
                            ? _advance
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _currentStep == 2
                              ? 'Buy $_serviceName'
                              : _currentStep == 4
                              ? 'View Receipt'
                              : 'Continue',
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
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A625D)),
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

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A625D)),
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
