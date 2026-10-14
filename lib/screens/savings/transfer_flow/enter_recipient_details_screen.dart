import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_card.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/modern_input.dart';
import 'transfer_model.dart';

class EnterRecipientDetailsScreen extends StatefulWidget {
  final TransferData? initialData;

  const EnterRecipientDetailsScreen({
    super.key,
    this.initialData,
  });

  @override
  State<EnterRecipientDetailsScreen> createState() =>
      _EnterRecipientDetailsScreenState();
}

class _EnterRecipientDetailsScreenState
    extends State<EnterRecipientDetailsScreen> {
  late TextEditingController _phoneController;
  late TransferData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? TransferData();
    _phoneController = TextEditingController(
      text: _data.recipientPhone?.replaceFirst('+233', '') ?? '',
    );
  }

  String get _normalizedPhone =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  bool get _isPhoneValid {
    final digits = _normalizedPhone;
    return RegExp(r'^\d{9}$').hasMatch(digits) ||
        RegExp(r'^0\d{9}$').hasMatch(digits);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Recipient Details',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient name display
            Text(
              'Recipient name',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    _data.recipientName ?? 'Not provided',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phone number input
            Text(
              'Phone Number',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ModernInput(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              label: 'Phone Number',
              prefixText: '+233 ',
              errorText: _phoneController.text.isEmpty || _isPhoneValid
                  ? null
                  : 'Enter a valid Ghana mobile number.',
              helperText: 'Enter 9 digits, or a 10-digit number starting with 0.',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),

            Text(
              'These details are entered manually and have not been verified against an Adepa account.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPhoneValid
                    ? () {
                        final digits = _normalizedPhone;
                        final localDigits = digits.startsWith('0')
                            ? digits.substring(1)
                            : digits;
                        final updated = _data.copyWith(
                          recipientPhone: '+233$localDigits',
                        );
                        context.push(
                          '/transfer/verify-recipient',
                          extra: updated,
                        );
                      }
                    : null,
                child: const Text('Review Recipient'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
