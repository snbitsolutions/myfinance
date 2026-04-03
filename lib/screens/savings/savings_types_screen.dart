import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/color_ext.dart';

/// A simple menu showing the different savings products/types a user can choose.
/// Tapping an item navigates directly to that type's detail screen.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.secondary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.secondary, theme.colorScheme.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Savings Type',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select the type that suits your needs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/savings/create'),
                      tooltip: 'Create New Savings',
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // List of savings types
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _types.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final type = _types[index];
                    return _SavingsTypeCard(
                      type: type,
                      onTap: () {
                        context.go('/savings/${Uri.encodeComponent(type.id)}');
                      },
                    );
                  },
                ),
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
