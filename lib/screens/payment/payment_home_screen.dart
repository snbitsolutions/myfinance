import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentHomeScreen extends StatefulWidget {
  const PaymentHomeScreen({super.key});

  @override
  State<PaymentHomeScreen> createState() => _PaymentHomeScreenState();
}

class _PaymentHomeScreenState extends State<PaymentHomeScreen> {
  static const green = Color(0xFF0C7D45);
  static const softBg = Color(0xFFF5F6F4);

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Savings', 'Payments Hub', 'Bills'];

    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = _selectedTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tabs[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: const [
                    _SavingsTab(),
                    _PaymentHubTab(),
                    _BillsTab(),
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
