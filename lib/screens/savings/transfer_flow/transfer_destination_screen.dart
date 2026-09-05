import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'transfer_model.dart';

class TransferDestinationScreen extends StatelessWidget {
  final TransferData? initialData;

  const TransferDestinationScreen({
    super.key,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData ?? TransferData();

    final destinations = [
      {
        'id': 'adepa_member',
        'name': 'Adepa Member',
        'icon': Icons.people,
      },
      {
        'id': 'bank_account',
        'name': 'Bank Account',
        'icon': Icons.account_balance,
      },
      {
        'id': 'mobile_money',
        'name': 'Mobile Money',
        'icon': Icons.phone_android,
      },
      {
        'id': 'international',
        'name': 'International',
        'icon': Icons.language,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Destination'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where would you like to transfer?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...destinations.map((dest) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () {
                    final updated = data.copyWith(
                      destination: dest['id'] as String,
                    );
                    context.push(
                      '/transfer/select-recipient',
                      extra: updated,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          dest['icon'] as IconData,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          dest['name'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
