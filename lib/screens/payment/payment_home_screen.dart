import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentHomeScreen extends StatelessWidget {
  const PaymentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _TopHeader(),
              const SizedBox(height: 18),
              _PortfolioSummaryCard(),
              const SizedBox(height: 26),
              Text(
                'Product Categories',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2A22),
                ),
              ),
              const SizedBox(height: 12),
              _CategoryTile(
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF0B8F57),
                tint: const Color(0xFFEAF4EE),
                title: 'Savings',
                subtitle: 'All your savings accounts\nand balances',
                amount: 'GH₵ 72,400.00',
                count: '3 accounts',
                amountColor: const Color(0xFF0B8F57),
                onTap: () => context.go('/savings'),
              ),
              const SizedBox(height: 10),
              _CategoryTile(
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFFD49A1F),
                tint: const Color(0xFFF8F0E1),
                title: 'Shares',
                subtitle: 'Your shareholding and\nshare value',
                amount: 'GH₵ 31,200.00',
                count: '1 account',
                amountColor: const Color(0xFFD49A1F),
              ),
              const SizedBox(height: 10),
              _CategoryTile(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF2E8B57),
                tint: const Color(0xFFEAF5EE),
                title: 'Investments',
                subtitle: 'Fixed deposits and other\ninvestments',
                amount: 'GH₵ 80,650.00',
                count: '2 investments',
                amountColor: const Color(0xFF0B8F57),
              ),
              const SizedBox(height: 10),
              _CategoryTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF3E7DBF),
                tint: const Color(0xFFEAF3FF),
                title: 'Loans',
                subtitle: 'Your active loans and\nrepayment status',
                amount: 'GH₵ 45,000.00',
                count: '1 active loan',
                amountColor: const Color(0xFF3E7DBF),
              ),
              const SizedBox(height: 26),
              _GrowCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0E5A3E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E5A3E).withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Products',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF183326),
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'All your financial products\nin one place',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF5F6E66),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            _HeaderButton(icon: Icons.search_rounded),
            const SizedBox(width: 8),
            _HeaderButton(icon: Icons.tune_rounded),
          ],
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;

  const _HeaderButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBE2DD)),
      ),
      child: Icon(icon, color: const Color(0xFF1E312A), size: 22),
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E5A3E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Portfolio Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'Hide balances',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Total Savings',
                  value: 'GH₵ 72,400.00',
                  sub: '3 accounts',
                  icon: Icons.savings_rounded,
                  iconColor: const Color(0xFFEAF5EE),
                  accent: const Color(0xFF9FD6B8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Total Shares',
                  value: 'GH₵ 31,200.00',
                  sub: '1 account',
                  icon: Icons.pie_chart_rounded,
                  iconColor: const Color(0xFFFCE9BF),
                  accent: const Color(0xFFF2C75C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Total Investments',
                  value: 'GH₵ 80,650.00',
                  sub: '2 investments',
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFFEAF5EE),
                  accent: const Color(0xFF6CD29D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Outstanding Loans',
                  value: 'GH₵ 45,000.00',
                  sub: '1 active loan',
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFFE7F0FF),
                  accent: const Color(0xFF9ABCF7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color iconColor;
  final Color accent;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                sub,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String title;
  final String subtitle;
  final String amount;
  final String count;
  final Color amountColor;
  final VoidCallback? onTap;

  const _CategoryTile({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.count,
    required this.amountColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDE8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1C3029),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF66756B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5E6C66),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF7B8A7F),
            size: 28,
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _GrowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFE3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow with Adepa',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF183326),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Explore more savings, investment\nand loan opportunities tailored\nfor you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF425A4E),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5A3E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Opportunities',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 8,
                  left: 18,
                  child: _CoinStack(count: 4),
                ),
                Positioned(
                  bottom: 0,
                  right: 16,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5A3E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                  ),
                ),
                Positioned(
                  bottom: 56,
                  right: 26,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6D9A0),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinStack extends StatelessWidget {
  final int count;

  const _CoinStack({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Transform.translate(
          offset: Offset(index * 4.0, 0),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFEAC05F),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCF9F2A), width: 2),
            ),
          ),
        );
      }),
    );
  }
}
