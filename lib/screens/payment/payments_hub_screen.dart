import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentsHubScreen extends StatelessWidget {
  const PaymentsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and History link
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      'Payments Hub',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C1F1E),
                        fontSize: 25,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/activity'),
                    child: Text(
                      'History',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF2E8B57),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2E8B57), Color(0xFF0E8F87)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.payments_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Go Cashless, Go Effortless',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pay your bills and top-up on the go anytime, anywhere.',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PAY MONEY Section
                    Text(
                      'PAY MONEY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      childAspectRatio: 0.85,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _PaymentGridTile(
                          icon: Icons.phone_rounded,
                          iconColor: const Color(0xFF2E8B57),
                          tint: const Color(0xFFEAF5EE),
                          title: 'Airtime',
                          subtitle: 'Buy airtime for\nany network',
                          route: '/payment?type=airtime',
                        ),
                        _PaymentGridTile(
                          icon: Icons.wifi_rounded,
                          iconColor: const Color(0xFF0E8F87),
                          tint: const Color(0xFFEAF4EF),
                          title: 'Data',
                          subtitle: 'Buy data bundles\nfor any network',
                          route: '/payment?type=data',
                        ),
                        _PaymentGridTile(
                          icon: Icons.receipt_rounded,
                          iconColor: const Color(0xFF3E7DBF),
                          tint: const Color(0xFFEAF3FF),
                          title: 'Bills',
                          subtitle: 'Pay your utility\nand service bills',
                          route: '/payment?type=bills',
                        ),
                        _PaymentGridTile(
                          icon: Icons.compare_arrows_rounded,
                          iconColor: const Color(0xFFD49A1F),
                          tint: const Color(0xFFF8F0E1),
                          title: 'Transfer',
                          subtitle: 'Send money to\naccounts & wallets',
                          route: '/payment?type=transfer',
                        ),
                        _PaymentGridTile(
                          icon: Icons.credit_card_rounded,
                          iconColor: const Color(0xFF2E8B57),
                          tint: const Color(0xFFEAF5EE),
                          title: 'Loan Payment',
                          subtitle: 'Repay your loans\nand facilities',
                          route: '/payment?type=loan-payment',
                        ),
                        _PaymentGridTile(
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFD64C56),
                          tint: const Color(0xFFFDE8EA),
                          title: 'Donations',
                          subtitle: 'Support causes\nyou care about',
                          route: '/payment?type=donations',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // MANAGE PAYMENTS Section
                    Text(
                      'MANAGE PAYMENTS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      childAspectRatio: 0.85,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _PaymentGridTile(
                          icon: Icons.schedule_rounded,
                          iconColor: const Color(0xFF2E8B57),
                          tint: const Color(0xFFEAF5EE),
                          title: 'Standing Orders',
                          subtitle: 'Automate recurring\npayments',
                          route: '/payment?type=standing-orders',
                        ),
                        _PaymentGridTile(
                          icon: Icons.people_rounded,
                          iconColor: const Color(0xFF3E7DBF),
                          tint: const Color(0xFFEAF3FF),
                          title: 'Saved Payees',
                          subtitle: 'View and manage\nsaved recipients',
                          route: '/payment?type=saved-payees',
                        ),
                        _PaymentGridTile(
                          icon: Icons.lock_rounded,
                          iconColor: const Color(0xFFD49A1F),
                          tint: const Color(0xFFF8F0E1),
                          title: 'Payment Limits',
                          subtitle: 'View and manage\nyour limits',
                          route: '/payment?type=limits',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bottom promotional banner
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentGridTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String subtitle;
  final String route;

  const _PaymentGridTile({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1F1E),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: const Color(0xFF5F6E66),
                  height: 1.2,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
