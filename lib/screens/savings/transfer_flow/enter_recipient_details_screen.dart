import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  bool get _canContinue =>
      _phoneController.text.trim().isNotEmpty &&
      _phoneController.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipient Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient name display
            Text(
              'Recipient Name',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
              ),
              child: Text(
                _data.recipientName ?? 'Unknown',
                style: theme.textTheme.bodyMedium,
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
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                prefixText: '+233 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue
                    ? () {
                        final updated = _data.copyWith(
                          recipientPhone: '+233${_phoneController.text.trim()}',
                        );
                        context.push(
                          '/transfer/verify-recipient',
                          extra: updated,
                        );
                      }
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
