import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_scaffold.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ghanaCardController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ghanaCardController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _showMessage(
      'KYC submission is unavailable until the backend verification endpoint is ready. Your details were not sent.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDateOfBirth() async {
    final today = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Select date of birth',
    );
    if (selectedDate == null || !mounted) return;

    _dateOfBirthController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'KYC Verification',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Verify your identity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the details registered with your account. Your information will only be submitted when the backend verification service is available.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ghanaCardController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Ghana Card number',
                hintText: 'GHA-XXXXXXXXX-X',
              ),
              validator: (value) {
                final card = value?.trim().toUpperCase() ?? '';
                return RegExp(r'^GHA-\d{8,9}-\d$').hasMatch(card)
                    ? null
                    : 'Use the format GHA-XXXXXXXXX-X';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('kyc-date-of-birth'),
              controller: _dateOfBirthController,
              readOnly: true,
              onTap: () => _pickDateOfBirth(),
              decoration: const InputDecoration(
                labelText: 'Date of birth',
                hintText: 'YYYY-MM-DD',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (value) {
                final date = value?.trim() ?? '';
                return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)
                    ? null
                    : 'Use the format YYYY-MM-DD';
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('KYC submission unavailable'),
            ),
          ],
        ),
      ),
    );
  }
}
