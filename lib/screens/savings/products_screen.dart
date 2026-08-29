import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Products', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _ProductTile(
                      title: 'Savings',
                      subtitle: 'All your savings accounts',
                      icon: Icons.savings_outlined,
                      onTap: () => context.go('/savings'),
                    ),
                    _ProductTile(
                      title: 'Investments',
                      subtitle: 'Fixed deposits and more',
                      icon: Icons.trending_up,
                      onTap: () => context.go('/investment'),
                    ),
                    _ProductTile(
                      title: 'Loans',
                      subtitle: 'Active loans and repayment',
                      icon: Icons.description_outlined,
                      onTap: () => context.go('/loans'),
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
}

class _ProductTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ProductTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
