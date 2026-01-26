import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import '../../core/app_scaffold.dart';
import '../../core/app_card.dart';
import '../../core/color_ext.dart';
import 'savings_model.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class SavingsTip {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String category;
  final List<String> actionableSteps;
  final String? estimatedSavings;

  const SavingsTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.category,
    this.actionableSteps = const [],
    this.estimatedSavings,
  });
}

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late SavingsType _selectedType;
  late TabController _tabController;
  List<SavingsTip> _displayedTips = [];

  // Comprehensive savings tips database
  static const List<SavingsTip> _allSavingsTips = [
    // Goal Setting & Planning
    SavingsTip(
      icon: Icons.lightbulb_outline,
      title: 'Set realistic goals',
      description:
          'Break down large savings goals into smaller, achievable milestones. Start with 3-6 months of expenses.',
      color: Colors.amber,
      category: 'Planning',
      actionableSteps: [
        'Calculate your monthly expenses',
        'Set a 3-month emergency fund goal first',
        'Break it into weekly or monthly targets',
        'Track progress and adjust as needed',
      ],
      estimatedSavings: '₵3,000-6,000 emergency fund',
    ),
    SavingsTip(
      icon: Icons.flag_outlined,
      title: 'Define your why',
      description:
          'Clear goals are easier to achieve. Whether it\'s a car, house, or emergency fund - visualize your target.',
      color: Colors.purple,
      category: 'Planning',
    ),
    SavingsTip(
      icon: Icons.calendar_month,
      title: 'Set a deadline',
      description:
          'Goals without deadlines are just wishes. Give each savings goal a realistic timeframe.',
      color: Colors.blue,
      category: 'Planning',
    ),

    // Automation & Systems
    SavingsTip(
      icon: Icons.calendar_today,
      title: 'Automate your savings',
      description:
          'Set up automatic transfers to save consistently each month. Treat savings like a non-negotiable bill.',
      color: Colors.blue,
      category: 'Automation',
      actionableSteps: [
        'Set up auto-transfer on payday',
        'Start with 10-15% of your income',
        'Transfer to a separate savings account',
        'Increase by 1% every 3 months',
      ],
      estimatedSavings: '₵200-500/month automatically saved',
    ),
    SavingsTip(
      icon: Icons.schedule,
      title: 'Save on payday',
      description:
          'Transfer to savings as soon as salary hits. You won\'t miss what you don\'t see in your account.',
      color: Colors.green,
      category: 'Automation',
    ),
    SavingsTip(
      icon: Icons.repeat,
      title: 'Round up purchases',
      description:
          'Round up transactions to the nearest ₵5 or ₵10 and save the difference. Small amounts add up!',
      color: Colors.teal,
      category: 'Automation',
    ),

    // Tracking & Review
    SavingsTip(
      icon: Icons.trending_up,
      title: 'Review regularly',
      description:
          'Track your progress and adjust your strategy as needed. Celebrate small wins to stay motivated.',
      color: Colors.green,
      category: 'Tracking',
    ),
    SavingsTip(
      icon: Icons.analytics_outlined,
      title: 'Track every expense',
      description:
          'What gets measured gets managed. Use this app to monitor spending patterns and find savings opportunities.',
      color: Colors.indigo,
      category: 'Tracking',
    ),
    SavingsTip(
      icon: Icons.assignment_outlined,
      title: 'Monthly budget review',
      description:
          'Spend 30 minutes each month reviewing expenses. Identify areas where you can cut back.',
      color: Colors.orange,
      category: 'Tracking',
    ),

    // Budgeting Rules
    SavingsTip(
      icon: Icons.account_balance_wallet,
      title: 'Follow the 50/30/20 rule',
      description:
          '50% needs, 30% wants, 20% savings. This simple budgeting rule helps balance spending and saving.',
      color: Colors.purple,
      category: 'Budgeting',
      actionableSteps: [
        'Calculate your monthly after-tax income',
        'Allocate 50% to essentials (rent, food, utilities)',
        'Budget 30% for wants (entertainment, dining)',
        'Save or invest the remaining 20%',
      ],
      estimatedSavings: '20% of income to savings each month',
    ),
    SavingsTip(
      icon: Icons.pie_chart_outline,
      title: 'Pay yourself first',
      description:
          'Save before spending. Allocate 10-20% of income to savings before budgeting for anything else.',
      color: Colors.deepPurple,
      category: 'Budgeting',
    ),
    SavingsTip(
      icon: Icons.money_off_outlined,
      title: 'Use cash envelopes',
      description:
          'Allocate cash for categories like dining or entertainment. When the envelope is empty, stop spending.',
      color: Colors.brown,
      category: 'Budgeting',
    ),

    // Expense Reduction
    SavingsTip(
      icon: Icons.shopping_cart_outlined,
      title: 'Cut unnecessary expenses',
      description:
          'Review subscriptions monthly. Cancel unused services and redirect that money to your savings goals.',
      color: Colors.orange,
      category: 'Expenses',
    ),
    SavingsTip(
      icon: Icons.restaurant_outlined,
      title: 'Pack your lunch',
      description:
          'Eating out costs 5x more than home-cooked meals. Save ₵200-500/month by bringing lunch to work.',
      color: Colors.red,
      category: 'Expenses',
      actionableSteps: [
        'Meal prep on Sundays for the week',
        'Buy lunch containers and thermos',
        'Cook extra dinner to use for lunch',
        'Track your savings by not eating out',
      ],
      estimatedSavings: '₵200-500 saved per month',
    ),
    SavingsTip(
      icon: Icons.local_cafe_outlined,
      title: 'Make coffee at home',
      description:
          'A daily ₵20 coffee costs ₵600/month. Brew at home and save ₵500+ monthly.',
      color: Colors.brown,
      category: 'Expenses',
    ),
    SavingsTip(
      icon: Icons.water_drop_outlined,
      title: 'Reduce utility bills',
      description:
          'Turn off lights and unplug devices when not in use. Small changes can save ₵50-100/month.',
      color: Colors.lightGreen,
      category: 'Expenses',
      actionableSteps: [
        'Unplug chargers and devices when not in use',
        'Use LED bulbs instead of regular bulbs',
        'Turn off lights when leaving rooms',
        'Use fans instead of AC when possible',
      ],
      estimatedSavings: '₵50-100 saved per month',
    ),
    SavingsTip(
      icon: Icons.local_gas_station_outlined,
      title: 'Reduce fuel costs',
      description:
          'Combine errands, carpool, or use public transport. Save 20-30% on monthly fuel expenses.',
      color: Colors.deepOrange,
      category: 'Expenses',
    ),

    // Smart Shopping
    SavingsTip(
      icon: Icons.local_atm_outlined,
      title: 'Use the 24-hour rule',
      description:
          'Wait 24 hours before making non-essential purchases. This reduces impulse buying significantly.',
      color: Colors.indigo,
      category: 'Shopping',
      actionableSteps: [
        'Add items to cart but don\'t buy immediately',
        'Wait 24 hours and reassess if you need it',
        'Ask: "Will I still want this tomorrow?"',
        'Track avoided impulse purchases',
      ],
      estimatedSavings: '₵100-300/month on avoided impulse buys',
    ),
    SavingsTip(
      icon: Icons.compare_arrows,
      title: 'Compare before you buy',
      description:
          'Always compare prices from different vendors. Use price comparison apps to find the best deals.',
      color: Colors.cyan,
      category: 'Shopping',
    ),
    SavingsTip(
      icon: Icons.shopping_bag_outlined,
      title: 'Shop with a list',
      description:
          'Make a shopping list and stick to it. Avoid browsing aisles to prevent impulse purchases.',
      color: Colors.pink,
      category: 'Shopping',
    ),
    SavingsTip(
      icon: Icons.sell_outlined,
      title: 'Buy generic brands',
      description:
          'Generic products are often 30-50% cheaper with similar quality. Start with groceries and toiletries.',
      color: Colors.lime,
      category: 'Shopping',
    ),
    SavingsTip(
      icon: Icons.discount_outlined,
      title: 'Use coupons and sales',
      description:
          'Plan major purchases around sales events. Use loyalty programs and discount codes to maximize savings.',
      color: Colors.red,
      category: 'Shopping',
    ),

    // Income Management
    SavingsTip(
      icon: Icons.savings_outlined,
      title: 'Save windfalls wisely',
      description:
          'Put at least 50% of bonuses, tax refunds, or unexpected income directly into savings.',
      color: Colors.teal,
      category: 'Income',
      actionableSteps: [
        'Transfer 50-70% immediately to savings',
        'Use 20-30% to pay off high-interest debt',
        'Spend remaining 10-20% on something you enjoy',
        'Avoid lifestyle inflation',
      ],
      estimatedSavings: 'Varies - can add thousands annually',
    ),
    SavingsTip(
      icon: Icons.work_outline,
      title: 'Start a side hustle',
      description:
          'Use skills to earn extra income. Even ₵500/month adds up to ₵6,000 yearly savings.',
      color: Colors.blueGrey,
      category: 'Income',
    ),
    SavingsTip(
      icon: Icons.card_giftcard_outlined,
      title: 'Monetize unused items',
      description:
          'Sell items you no longer need. Convert clutter into cash for your savings goals.',
      color: Colors.purple,
      category: 'Income',
    ),

    // Smart Habits
    SavingsTip(
      icon: Icons.no_drinks_outlined,
      title: 'Reduce dining out',
      description:
          'Limit restaurant visits to once or twice weekly. Cook at home to save ₵300-800 monthly.',
      color: Colors.red,
      category: 'Habits',
    ),
    SavingsTip(
      icon: Icons.directions_walk_outlined,
      title: 'Walk or bike short distances',
      description:
          'For trips under 2km, walk or bike instead of driving. Saves fuel and improves health.',
      color: Colors.green,
      category: 'Habits',
    ),
    SavingsTip(
      icon: Icons.library_books_outlined,
      title: 'Use the library',
      description:
          'Borrow books, movies, and magazines instead of buying. Most libraries offer free resources.',
      color: Colors.indigo,
      category: 'Habits',
    ),
    SavingsTip(
      icon: Icons.settings_outlined,
      title: 'DIY when possible',
      description:
          'Learn basic home repairs, car maintenance, or cooking. YouTube tutorials can save hundreds monthly.',
      color: Colors.orange,
      category: 'Habits',
    ),

    // Emergency & Protection
    SavingsTip(
      icon: Icons.health_and_safety_outlined,
      title: 'Build emergency fund first',
      description:
          'Aim for 3-6 months of expenses in an easily accessible account before other goals.',
      color: Colors.red,
      category: 'Protection',
    ),
    SavingsTip(
      icon: Icons.security_outlined,
      title: 'Keep savings separate',
      description:
          'Use a separate account for savings. Out of sight, out of mind reduces temptation to spend.',
      color: Colors.blueGrey,
      category: 'Protection',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = SavingsType.memberSaving;
    _tabController = TabController(length: 2, vsync: this);
    _loadRandomTips();
  }

  void _loadRandomTips() {
    final random = Random();
    final shuffled = List<SavingsTip>.from(_allSavingsTips)..shuffle(random);
    setState(() {
      _displayedTips = shuffled.take(3).toList(); // Reduced to 3 tips
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock list with multiple savings types
    final allSavings = [
      Savings(
        id: '1',
        title: 'Emergency Fund',
        balance: 1200,
        target: 2000,
        type: SavingsType.memberSaving,
      ),
      Savings(
        id: '2',
        title: 'Daily Expenses',
        balance: 450,
        target: 1000,
        type: SavingsType.currentSaving,
      ),
      Savings(
        id: '3',
        title: 'Children Education',
        balance: 5000,
        target: 10000,
        type: SavingsType.kiddySaving,
      ),
      Savings(
        id: '4',
        title: '12-Month Fixed Deposit',
        balance: 2000,
        target: 2000,
        type: SavingsType.fixedDeposit,
        interestRate: 5.5,
        maturityDate: DateTime.now().add(const Duration(days: 365)),
      ),
      Savings(
        id: '5',
        title: 'Vacation Fund',
        balance: 300,
        target: 1500,
        type: SavingsType.currentSaving,
      ),
      Savings(
        id: '6',
        title: 'Group Savings',
        balance: 3200,
        target: 5000,
        type: SavingsType.memberSaving,
      ),
    ];

    // Filter by selected type
    final savings = allSavings.where((s) => s.type == _selectedType).toList();
    final totalBalance = allSavings.fold<double>(
      0,
      (sum, s) => sum + s.balance,
    );

    return AppScaffold(
      title: 'My Savings',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/savings/create'),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacitySafe(
                0.6,
              ),
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Goals'),
                Tab(text: 'Overview'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsTab(theme, allSavings, savings, totalBalance),
                _buildOverviewTab(theme, allSavings, totalBalance),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(
    ThemeData theme,
    List<Savings> allSavings,
    List<Savings> savings,
    double totalBalance,
  ) {
    final totalTarget = allSavings.fold<double>(0, (sum, s) => sum + s.target);
    final overallProgress = totalTarget > 0 ? totalBalance / totalTarget : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Enhanced Summary Card
          AppCard(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacitySafe(0.1),
                    theme.colorScheme.secondary.withOpacitySafe(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Saved',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₵${totalBalance.toStringAsFixed(2)}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withOpacitySafe(
                              0.2,
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Overall Progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Overall Progress',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.7),
                              ),
                            ),
                            Text(
                              '${(overallProgress * 100).toStringAsFixed(1)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: overallProgress.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.onSurface
                                .withOpacitySafe(0.1),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStat(
                            theme,
                            '${allSavings.length}',
                            'Active Goals',
                            Icons.flag,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: theme.colorScheme.outline.withOpacitySafe(0.2),
                        ),
                        Expanded(
                          child: _buildQuickStat(
                            theme,
                            '₵${totalTarget.toStringAsFixed(0)}',
                            'Total Target',
                            Icons.track_changes,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions - Simplified
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  theme,
                  'Deposit',
                  Icons.add_circle_outline,
                  theme.colorScheme.primary,
                  () => context.go('/payment'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  theme,
                  'Withdraw',
                  Icons.remove_circle_outline,
                  theme.colorScheme.error,
                  () => context.go('/payment'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  theme,
                  'History',
                  Icons.history,
                  theme.colorScheme.tertiary,
                  () => _showComingSoon(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Savings Type Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SavingsType.values.map((type) {
                final isSelected = type == _selectedType;
                final typeCount = allSavings
                    .where((s) => s.type == type)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (typeCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.3)
                                    : theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$typeCount',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Savings List
          Expanded(
            child: savings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedType.icon,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacitySafe(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_selectedType.label} yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start building your savings today!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/savings/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Savings Goal'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: savings.length,
                    itemBuilder: (context, i) {
                      final s = savings[i];
                      final progress = (s.balance / s.target).clamp(0.0, 1.0);
                      final remaining = s.target - s.balance;
                      return GestureDetector(
                        onTap: () => context.go('/savings/${s.id}'),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withOpacitySafe(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      s.type.icon,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (s.type ==
                                                SavingsType.fixedDeposit &&
                                            s.interestRate != null)
                                          Text(
                                            '${s.interestRate!.toStringAsFixed(2)}% p.a.',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₵${s.balance.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                      Text(
                                        'of ₵${s.target.toStringAsFixed(0)}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacitySafe(0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress Bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${(progress * 100).toStringAsFixed(0)}% Complete',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacitySafe(0.7),
                                            ),
                                      ),
                                      Text(
                                        '₵${remaining.toStringAsFixed(0)} left',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: theme
                                          .colorScheme
                                          .onSurface
                                          .withOpacitySafe(0.06),
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (s.maturityDate != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: theme
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Matures: ${s.maturityDate!.day}/${s.maturityDate!.month}/${s.maturityDate!.year}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    ThemeData theme,
    List<Savings> allSavings,
    double totalBalance,
  ) {
    final totalTarget = allSavings.fold<double>(0, (sum, s) => sum + s.target);
    final totalInterest = allSavings.fold<double>(
      0,
      (sum, s) => sum + (s.balance * 0.02), // Mock 2% interest
    );

    // Calculate breakdown by type
    final breakdownData = SavingsType.values
        .map((type) {
          final typeSavings = allSavings.where((s) => s.type == type).toList();
          final typeBalance = typeSavings.fold<double>(
            0,
            (sum, s) => sum + s.balance,
          );
          return {
            'type': type,
            'balance': typeBalance,
            'count': typeSavings.length,
          };
        })
        .where((data) => data['balance'] as double > 0)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats - Simplified & Clean
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\u20b5${totalBalance.toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Total Saved',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '\u20b5${totalInterest.toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Interest',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.track_changes,
                          color: theme.colorScheme.error,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\u20b5${(totalTarget - totalBalance).toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'To Go',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.flag,
                              size: 20,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${allSavings.length}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active Goals',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.track_changes,
                              size: 20,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₵${(totalTarget - totalBalance).toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'To Reach Goals',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Savings Breakdown by Type - Collapsible
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: false,
            title: Text(
              'Savings Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: breakdownData.asMap().entries.map((entry) {
                    final data = entry.value;
                    final type = data['type'] as SavingsType;
                    final balance = data['balance'] as double;
                    final count = data['count'] as int;
                    final percentage = totalBalance > 0
                        ? (balance / totalBalance) * 100
                        : 0.0;
                    final isLast = entry.key == breakdownData.length - 1;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacitySafe(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                type.icon,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        type.label,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        '₵${balance.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: percentage / 100,
                                            minHeight: 4,
                                            backgroundColor: theme
                                                .colorScheme
                                                .onSurface
                                                .withOpacitySafe(0.1),
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${percentage.toStringAsFixed(0)}%',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacitySafe(0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count goal${count > 1 ? 's' : ''}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacitySafe(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isLast) ...[
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: theme.colorScheme.outline.withOpacitySafe(
                              0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Savings Tips Header with Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Tips',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _loadRandomTips,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New Tips'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Display random tips from the database
          ..._displayedTips.asMap().entries.map((entry) {
            final index = entry.key;
            final tip = entry.value;
            return Column(
              children: [
                if (index > 0) const SizedBox(height: 8),
                _buildTipCard(
                  theme,
                  tip.icon,
                  tip.title,
                  tip.description,
                  tip.color,
                  tip.category,
                  onTap: () => _showTipDetails(context, tip),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTipCard(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
    Color color,
    String category, {
    VoidCallback? onTap,
  }) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 14,
                            color: color.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap for details',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDetails(BuildContext context, SavingsTip tip) {
    final theme = Theme.of(context);
    final relatedTips = _allSavingsTips
        .where((t) => t.category == tip.category && t.title != tip.title)
        .take(3)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: tip.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(tip.icon, color: tip.color, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tip.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tip.category,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: tip.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'About',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.8),
                        height: 1.5,
                      ),
                    ),

                    // Estimated Savings
                    if (tip.estimatedSavings != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tip.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tip.color.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              color: tip.color,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Potential Savings',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: tip.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    tip.estimatedSavings!,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Action Steps
                    if (tip.actionableSteps.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Action Steps',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...tip.actionableSteps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: tip.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: tip.color.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: tip.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    step,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Related Tips
                    if (relatedTips.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'More ${tip.category} Tips',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...relatedTips.map((relatedTip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _showTipDetails(context, relatedTip);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.2,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    relatedTip.icon,
                                    color: relatedTip.color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      relatedTip.title,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: theme.colorScheme.onSurface
                                        .withOpacitySafe(0.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
