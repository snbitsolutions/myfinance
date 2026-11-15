import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/color_ext.dart';
import 'savings_model.dart';

/// A menu showing the different savings products/types a user can create.
class SavingsTypesScreen extends StatelessWidget {
  const SavingsTypesScreen({super.key});

  static const _types = <_SavingsType>[
    _SavingsType(
      id: 'member-savings',
      label: 'Member Savings',
      icon: Icons.groups_rounded,
      description: 'Exclusive savings plan for registered members',
      color: Color(0x00000000),
    ),
    _SavingsType(
      id: 'current-savings',
      label: 'Current Savings',
      icon: Icons.account_balance_wallet_rounded,
      description: 'Flexible savings with easy withdrawals',
      color: Color(0xFF3498DB),
    ),
    _SavingsType(
      id: 'kiddy-savings',
      label: 'Kiddy Savings',
      icon: Icons.child_care_rounded,
      description: 'Save for your children\'s future',
      color: Color(0xFFFF6B9D),
    ),
    _SavingsType(
      id: 'fixed-savings',
      label: 'Fixed Savings',
      icon: Icons.lock_clock_rounded,
      description: 'Lock your savings for better returns',
      color: Color(0xFF9B59B6),
    ),
    _SavingsType(
      id: 'emergency-fund',
      label: 'Emergency Fund',
      icon: Icons.medical_information_rounded,
      description: 'Build a safety net for unexpected expenses',
      color: Color(0xFFE74C3C),
    ),
    _SavingsType(
      id: 'goal-savings',
      label: 'Goal Savings',
      icon: Icons.flag_rounded,
      description: 'Save towards achieving your financial goals',
      color: Color(0xFF16A085),
    ),
    _SavingsType(
      id: 'vacation-savings',
      label: 'Vacation',
      icon: Icons.flight_takeoff_rounded,
      description: 'Plan and save for your dream vacation',
      color: Color(0xFFF39C12),
    ),
    _SavingsType(
      id: 'education-savings',
      label: 'Education',
      icon: Icons.school_rounded,
      description: 'Invest in education and future growth',
      color: Color(0xFF8E44AD),
    ),
  ];

  Future<void> _showCreateTypePicker(BuildContext context) async {
    final selected = await showModalBottomSheet<SavingsType>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final maxListHeight = MediaQuery.sizeOf(sheetContext).height * 0.45;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Savings Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick the type you want to create before continuing.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.62),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: SavingsType.values
                          .map(
                            (type) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacitySafe(0.12),
                                child: Icon(
                                  type.icon,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(type.label),
                              subtitle: Text(type.description),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.of(sheetContext).pop(type),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || selected == null) return;

    final typeQuery = switch (selected) {
      SavingsType.memberSaving => 'member',
      SavingsType.currentSaving => 'current',
      SavingsType.kiddySaving => 'kiddy',
      SavingsType.fixedDeposit => 'fixed',
    };
    context.go('/savings/create?type=$typeQuery');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundTop = theme.colorScheme.primary.withOpacitySafe(0.10);
    final backgroundMid = theme.colorScheme.secondary.withOpacitySafe(0.06);
    final backgroundBottom = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundTop, backgroundMid, backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacitySafe(0.08),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary.withOpacitySafe(0.07),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => context.go('/savings'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose Savings Type',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select the type that suits your needs',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacitySafe(0.68),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showCreateTypePicker(context),
                          tooltip: 'Create New Savings',
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _types.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final type = _types[index];
                        return _SavingsTypeCard(
                          type: type,
                          onTap: () {
                            final typeQuery = switch (type.id) {
                              'member-savings' => 'member',
                              'current-savings' => 'current',
                              'kiddy-savings' => 'kiddy',
                              'fixed-savings' => 'fixed',
                              _ => 'member',
                            };
                            context.go('/savings/create?type=$typeQuery');
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsType {
  final String id;
  final String label;
  final IconData icon;
  final String description;
  final Color color;

  const _SavingsType({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.color,
  });
}

class _SavingsTypeCard extends StatelessWidget {
  final _SavingsType type;
  final VoidCallback onTap;

  const _SavingsTypeCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = type.id == 'member-savings'
        ? theme.colorScheme.primary
        : type.color;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withOpacitySafe(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
