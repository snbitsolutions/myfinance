import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import '../../../core/modern_input.dart';
import 'transfer_model.dart';

class SelectRecipientScreen extends StatefulWidget {
  final TransferData? initialData;

  const SelectRecipientScreen({super.key, this.initialData});

  @override
  State<SelectRecipientScreen> createState() => _SelectRecipientScreenState();
}

class _SelectRecipientScreenState extends State<SelectRecipientScreen> {
  late TextEditingController _searchController;
  late TransferData _data;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _data = widget.initialData ?? TransferData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Select Recipient',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModernInput(
                controller: _searchController,
                label: 'Recipient name',
                prefixIcon: Icons.person_outline,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter the member’s name and phone number. These details are for preparing the transfer only and are not checked against an account.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _searchController.text.trim().isEmpty
                      ? null
                      : () {
                          final updated = _data.copyWith(
                            recipientName: _searchController.text.trim(),
                          );
                          context.push(
                            '/transfer/enter-details',
                            extra: updated,
                          );
                        },
                  child: const Text('Enter Recipient Phone'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
