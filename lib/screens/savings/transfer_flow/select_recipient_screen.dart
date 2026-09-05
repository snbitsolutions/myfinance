import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'transfer_model.dart';

class SelectRecipientScreen extends StatefulWidget {
  final TransferData? initialData;

  const SelectRecipientScreen({
    super.key,
    this.initialData,
  });

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

    // Mock recipients
    final allRecipients = [
      {
        'id': 'member_001',
        'name': 'John Mensah',
        'type': 'Member',
      },
      {
        'id': 'member_002',
        'name': 'Ama Gyasi',
        'type': 'Member',
      },
      {
        'id': 'member_003',
        'name': 'Kwame Asante',
        'type': 'Member',
      },
      {
        'id': 'member_004',
        'name': 'Abena Owusu',
        'type': 'Member',
      },
    ];

    final searchQuery = _searchController.text.toLowerCase();
    final filteredRecipients = allRecipients
        .where((r) =>
            (r['name'] as String).toLowerCase().contains(searchQuery) ||
            (r['id'] as String).toLowerCase().contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Recipient'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search recipient name or ID...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Recent/Saved Recipients
              if (filteredRecipients.isEmpty && _searchController.text.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Recipients',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...allRecipients.take(3).map((recipient) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildRecipientTile(context, recipient),
                      );
                    }),
                  ],
                )
              else if (filteredRecipients.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Results',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...filteredRecipients.map((recipient) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildRecipientTile(context, recipient),
                      );
                    }),
                  ],
                )
              else
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.person_off,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recipients found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientTile(
    BuildContext context,
    Map<String, dynamic> recipient,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        final updated = _data.copyWith(
          recipientId: recipient['id'] as String,
          recipientName: recipient['name'] as String,
        );
        context.push(
          '/transfer/enter-details',
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
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                (recipient['name'] as String)[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipient['name'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipient['type'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
