import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';
import '../../core/app_card.dart';

class PaymentHomeScreen extends StatefulWidget {
  const PaymentHomeScreen({super.key});

  @override
  State<PaymentHomeScreen> createState() => _PaymentHomeScreenState();
}

/// Placeholder screen for the (now-empty) Payment page. The real payment flow
/// screens remain available at their routes; this placeholder is returned when
/// a user navigates to /payment with no specific source (we keep the route but
/// show an intentionally empty page while payments are being rebuilt).
class PaymentPlaceholderScreen extends StatelessWidget {
  const PaymentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payments',
      showBack: false,
      child: const Center(child: SizedBox.shrink()),
    );
  }
}

class _PaymentHomeScreenState extends State<PaymentHomeScreen> {
  static const green = Color(0xFF0C7D45);
  static const softBg = Color(0xFFF5F6F4);

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    // Implement the Products home while keeping original tab widgets intact below.
    return AppScaffold(
      title: 'My Products',
      showBack: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF0C7D45)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Color(0xFF0C7D45)),
          onPressed: () {},
        ),
      ],
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E6E42),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.account_tree_outlined, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Products',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All your financial products\n in one place',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                                height: 1.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Portfolio summary card
              AppCard(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E6E42), Color(0xFF0B5F37)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Portfolio Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Hide balances', style: TextStyle(color: Colors.white70)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _SummaryTile(
                            icon: Icons.savings_outlined,
                            label: 'Total Savings',
                            amount: 'GH₵ 72,400.00',
                            count: '3 accounts',
                            color: Colors.greenAccent,
                          ),
                          _DividerVertical(),
                          _SummaryTile(
                            icon: Icons.pie_chart_outline,
                            label: 'Total Shares',
                            amount: 'GH₵ 31,200.00',
                            count: '1 account',
                            color: Colors.amber,
                          ),
                          _DividerVertical(),
                          _SummaryTile(
                            icon: Icons.show_chart,
                            label: 'Total Investments',
                            amount: 'GH₵ 80,650.00',
                            count: '2 investments',
                            color: Colors.lightGreenAccent,
                          ),
                          _DividerVertical(),
                          _SummaryTile(
                            icon: Icons.description_outlined,
                            label: 'Outstanding Loans',
                            amount: 'GH₵ 45,000.00',
                            count: '1 active loan',
                            color: Colors.lightBlueAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Product Categories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              // Products list
              _productCategory(
                context,
                label: 'Savings',
                description: 'All your savings accounts\n and balances',
                amount: 'GH₵ 72,400.00',
                count: '3 accounts',
                color: const Color(0xFF0E6E42),
                onTap: () => context.go('/savings'),
              ),

              _productCategory(
                context,
                label: 'Shares',
                description: 'Your shareholding and\n share value',
                amount: 'GH₵ 31,200.00',
                count: '1 account',
                color: const Color(0xFFFFB703),
                onTap: () {},
              ),

              _productCategory(
                context,
                label: 'Investments',
                description: 'Fixed deposits and other\n investments',
                amount: 'GH₵ 80,650.00',
                count: '2 investments',
                color: const Color(0xFF0E6E42),
                onTap: () {},
              ),

              _productCategory(
                context,
                label: 'Loans',
                description: 'Your active loans and\n repayment status',
                amount: 'GH₵ 45,000.00',
                count: '1 active loan',
                color: const Color(0xFF3B82F6),
                onTap: () {},
              ),

              const SizedBox(height: 12),

              // Promotional banner
              AppCard(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFEFF7EF),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grow with Adepa',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0C7D45),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Explore more savings, investment\n and loan opportunities tailored\n for you.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E6E42),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {},
                              child: const Text('Explore Opportunities'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Illustration placeholder
                      Container(
                        width: 88,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Icon(Icons.account_balance_wallet, color: Color(0xFF0E6E42), size: 36)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Bottom spacing to mimic bottom navigation bar spacing in design
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsTab extends StatelessWidget {
  const _SavingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Text(
        //   'Good morning, Kennedy',
        //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        //     fontWeight: FontWeight.w800,
        //     color: Colors.black87,
        //   ),
        // ),
        // const SizedBox(height: 4),
        // Text(
        //   'Your account is ready for your next payment',
        //   style: Theme.of(
        //     context,
        //   ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        // ),
        // const SizedBox(height: 18),
        GestureDetector(
          onTap: () => context.go('/savings'),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF0E6E42), Color(0xFF0B5F37)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Member Savings',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'GH₵ 45,000.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+ GH₵ 1,120.00 this month',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Quick actions',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _QuickActionTile(
              icon: Icons.download_outlined,
              label: 'Deposit',
              onTap: () => context.go('/savings'),
            ),
            _QuickActionTile(
              icon: Icons.upload_outlined,
              label: 'Withdraw',
              onTap: () => context.go('/payment'),
            ),
            _QuickActionTile(
              icon: Icons.swap_horiz,
              label: 'Transfer',
              onTap: () => context.go('/transfer'),
            ),
            _QuickActionTile(
              icon: Icons.wallet,
              label: 'Payments',
              onTap: () => context.go('/payment'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => context.go('/payment'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Color(0xFF0C7D45),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enjoy seamless banking and instant transfers.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Recent transactions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              'View all',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF0C7D45),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TransactionItem(
          icon: Icons.arrow_downward,
          label: 'Deposit',
          detail: 'From Mobile Money',
          amount: 'GH₵ 1,000.00',
          positive: true,
        ),
        const SizedBox(height: 10),
        _TransactionItem(
          icon: Icons.arrow_upward,
          label: 'Transfer',
          detail: 'To John Mensah',
          amount: 'GH₵ 1,000.00',
          positive: false,
        ),
      ],
    );
  }
}

class _PaymentHubTab extends StatelessWidget {
  const _PaymentHubTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E6E42), Color(0xFF0B5F37)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total paid this month',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'GH₵ 8,640.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => context.go('/transfer'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: Color(0xFF0C7D45),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make payments quickly and securely.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Pay money',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            _ServiceTile(
              label: 'Airtime',
              icon: Icons.phone_iphone,
              onTap: () => context.go('/payment'),
            ),
            _ServiceTile(
              label: 'Data',
              icon: Icons.signal_cellular_4_bar,
              onTap: () => context.go('/payment'),
            ),
            _ServiceTile(
              label: 'Bills',
              icon: Icons.receipt_long,
              onTap: () => context.go('/payment'),
            ),
            _ServiceTile(
              label: 'Transfer',
              icon: Icons.swap_horiz,
              onTap: () => context.go('/transfer'),
            ),
            _ServiceTile(
              label: 'Loan',
              icon: Icons.account_balance_wallet,
              onTap: () => context.go('/loan-status'),
            ),
            _ServiceTile(
              label: 'Donations',
              icon: Icons.favorite_border,
              onTap: () => context.go('/payment'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Manage payments',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.3,
          children: const [
            _ManagerTile(icon: Icons.receipt_long, label: 'Standing Orders'),
            _ManagerTile(
              icon: Icons.check_circle_outline,
              label: 'Saved Payees',
            ),
            _ManagerTile(icon: Icons.shield_outlined, label: 'Payment Limits'),
            _ManagerTile(icon: Icons.credit_card, label: 'Cards'),
          ],
        ),
      ],
    );
  }
}

class _BillsTab extends StatelessWidget {
  const _BillsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Search billers',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Categories',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(label: 'All', selected: true),
            _CategoryChip(label: 'Utilities'),
            _CategoryChip(label: 'TV & Internet'),
            _CategoryChip(label: 'Education'),
            _CategoryChip(label: 'Others'),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'Popular billers',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              'View all',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF0C7D45),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: const [
            _BillerLogo(label: 'ECG'),
            _BillerLogo(label: 'Ghana Water'),
            _BillerLogo(label: 'DSTV'),
            _BillerLogo(label: 'GoTv'),
            _BillerLogo(label: 'NHIS'),
            _BillerLogo(label: 'Betway'),
          ],
        ),
        const SizedBox(height: 18),
        _BillItem(
          label: 'Electricity Company of Ghana',
          subtitle: 'Pay your electricity bills',
        ),
        const SizedBox(height: 10),
        _BillItem(
          label: 'Ghana Water Company Limited',
          subtitle: 'Pay your water bills',
        ),
        const SizedBox(height: 10),
        _BillItem(label: 'DSTV', subtitle: 'Pay your DSTV subscription'),
      ],
    );
  }
}

// Small helper used in the portfolio summary
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final String count;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerVertical extends StatelessWidget {
  const _DividerVertical({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white24,
    );
  }
}

// Helper function for product category rows used in the product list
Widget _productCategory(
  BuildContext context, {
  required String label,
  required String description,
  required String amount,
  required String count,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: color == const Color(0xFFFFB703) ? const Color(0xFFFF8A00) : const Color(0xFF0C7D45),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count,
                style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    ),
  );
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0C7D45), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final String amount;
  final bool positive;

  const _TransactionItem({
    required this.icon,
    required this.label,
    required this.detail,
    required this.amount,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0C7D45), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: positive ? const Color(0xFF0C7D45) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0C7D45), size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ManagerTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0C7D45), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _CategoryChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF4EE) : const Color(0xFFF4F5F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF0C7D45) : Colors.black54,
        ),
      ),
    );
  }
}

class _BillerLogo extends StatelessWidget {
  final String label;

  const _BillerLogo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BillItem extends StatelessWidget {
  final String label;
  final String subtitle;

  const _BillItem({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Color(0xFF0C7D45),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    );
  }
}
