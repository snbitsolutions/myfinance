import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_card.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import 'transfer_model.dart';

class TransferDestinationScreen extends StatelessWidget {
  final TransferData? initialData;

  const TransferDestinationScreen({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = initialData ?? TransferData();

    final destinations = [
      {'id': 'adepa_member', 'name': 'Adepa Member', 'icon': Icons.people},
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
      {'id': 'international', 'name': 'International', 'icon': Icons.language},
    ];

    return AppScaffold(
      title: 'Select Destination',
      child: SingleChildScrollView(
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
              final isMember = dest['id'] == 'adepa_member';
              return AppCard(
                padding: EdgeInsets.zero,
                onTap: isMember
                    ? () {
                        final updated = data.copyWith(
                          destination: dest['id'] as String,
                        );
                        context.push(
                          '/transfer/select-recipient',
                          extra: updated,
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacitySafe(
                            0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          dest['icon'] as IconData,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dest['name'] as String,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isMember)
                              Text(
                                'Unavailable until backend support is added',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isMember)
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                    ],
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
