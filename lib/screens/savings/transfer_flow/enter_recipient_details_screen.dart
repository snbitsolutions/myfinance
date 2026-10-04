import 'package:flutter/material.dart';
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
    _phoneController = TextEditingController();
    _data = widget.initialData ?? TransferData();
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
              'Recipient name (unverified)',
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),

            Text(
              'Recipient lookup is unavailable. You can review the details, but the transfer cannot continue until the backend can verify the recipient.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: const Text('Recipient lookup unavailable'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
