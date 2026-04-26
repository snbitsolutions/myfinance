import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import '../../core/action_triple_row.dart';
import '../../core/app_card.dart';
import '../../core/balance_card_shell.dart';
import '../../core/color_ext.dart';
import '../../core/layout/responsive.dart';
import 'savings_model.dart';
import 'savings_storage.dart';

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

enum GoalsSortOption { closestToGoal, highestBalance, newest }

class _SavingsScreenState extends State<SavingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoalsSortOption _goalsSort = GoalsSortOption.closestToGoal;
  SavingsType? _selectedTypeFilter;
  List<SavingsTip> _displayedTips = [];
  final List<Savings> _userCreatedGoals = [];
  String? _lastIngestedGoalId;

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
      estimatedSavings: 'GH₵3,000-6,000 emergency fund',
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
      estimatedSavings: 'GH₵200-500/month automatically saved',
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
          'Round up transactions to the nearest GH₵5 or GH₵10 and save the difference. Small amounts add up!',
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
          'Eating out costs 5x more than home-cooked meals. Save GH₵200-500/month by bringing lunch to work.',
      color: Colors.red,
      category: 'Expenses',
      actionableSteps: [
        'Meal prep on Sundays for the week',
        'Buy lunch containers and thermos',
        'Cook extra dinner to use for lunch',
        'Track your savings by not eating out',
      ],
      estimatedSavings: 'GH₵200-500 saved per month',
    ),
    SavingsTip(
      icon: Icons.local_cafe_outlined,
      title: 'Make coffee at home',
      description:
          'A daily GH₵20 coffee costs GH₵600/month. Brew at home and save GH₵500+ monthly.',
      color: Colors.brown,
      category: 'Expenses',
    ),
    SavingsTip(
      icon: Icons.water_drop_outlined,
      title: 'Reduce utility bills',
      description:
          'Turn off lights and unplug devices when not in use. Small changes can save GH₵50-100/month.',
      color: Colors.lightGreen,
      category: 'Expenses',
      actionableSteps: [
        'Unplug chargers and devices when not in use',
        'Use LED bulbs instead of regular bulbs',
        'Turn off lights when leaving rooms',
        'Use fans instead of AC when possible',
      ],
      estimatedSavings: 'GH₵50-100 saved per month',
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
      estimatedSavings: 'GH₵100-300/month on avoided impulse buys',
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
          'Use skills to earn extra income. Even GH₵500/month adds up to GH₵6,000 yearly savings.',
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
          'Limit restaurant visits to once or twice weekly. Cook at home to save GH₵300-800 monthly.',
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
    _tabController = TabController(length: 2, vsync: this);
    _loadRandomTips();
    _loadPersistedGoals();
  }

  Future<void> _loadPersistedGoals() async {
    final goals = await SavingsStorage.loadGoals();
    if (!mounted) return;
    setState(() {
      _userCreatedGoals
        ..clear()
        ..addAll(goals);
    });
  }

  Future<void> _addGoalIfMissing(Savings incoming) async {
    final alreadyExists = _userCreatedGoals.any(
      (goal) => goal.id == incoming.id,
    );
    if (alreadyExists) return;

    setState(() {
      _userCreatedGoals.insert(0, incoming);
    });
    await SavingsStorage.saveGoals(_userCreatedGoals);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final incoming = GoRouterState.of(context).extra;
    if (incoming is! Savings) return;
    if (_lastIngestedGoalId == incoming.id) return;

    _lastIngestedGoalId = incoming.id;
    _addGoalIfMissing(incoming);
  }

  void _loadRandomTips() {
    final random = Random();
    final shuffled = List<SavingsTip>.from(_allSavingsTips)..shuffle(random);
    setState(() {
      _displayedTips = shuffled.take(3).toList(); // Reduced to 3 tips
    });
  }

  Future<void> _showCreateSavingsTypePicker() async {
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
                                backgroundColor: _goalAccentColor(
                                  theme,
                                  type,
                                ).withOpacitySafe(0.14),
                                child: Icon(
                                  type.icon,
                                  color: _goalAccentColor(theme, type),
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

    if (!mounted || selected == null) return;

    final typeQuery = switch (selected) {
      SavingsType.memberSaving => 'member',
      SavingsType.currentSaving => 'current',
      SavingsType.kiddySaving => 'kiddy',
      SavingsType.fixedDeposit => 'fixed',
    };
    context.go('/savings/create?type=$typeQuery');
  }

  Future<void> _showSavingsTypeLongPressPicker() async {
    final selected = await showModalBottomSheet<SavingsType>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
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
                  'Long-press quick action shortcut: pick a type to filter goals.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.62),
                  ),
                ),
                const SizedBox(height: 12),
                ...SavingsType.values.map(
                  (type) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _goalAccentColor(
                        theme,
                        type,
                      ).withOpacitySafe(0.14),
                      child: Icon(
                        type.icon,
                        color: _goalAccentColor(theme, type),
                      ),
                    ),
                    title: Text(type.label),
                    subtitle: Text(type.description),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(sheetContext).pop(type),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go('/savings/types');
                  },
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('Open Full Type Catalog'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedTypeFilter = selected;
      _tabController.animateTo(0);
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
      ..._userCreatedGoals, // Add user-created goals first
      Savings(
        id: 'emergency-fund',
        title: 'Emergency Fund',
        balance: 1200,
        target: 2000,
        type: SavingsType.memberSaving,
      ),
      Savings(
        id: 'current-savings',
        title: 'Daily Expenses',
        balance: 450,
        target: 1000,
        type: SavingsType.currentSaving,
      ),
      Savings(
        id: 'education-savings',
        title: 'Children Education',
        balance: 5000,
        target: 10000,
        type: SavingsType.kiddySaving,
      ),
      Savings(
        id: 'fixed-savings',
        title: '12-Month Fixed Deposit',
        balance: 2000,
        target: 2000,
        type: SavingsType.fixedDeposit,
        interestRate: 5.5,
        maturityDate: DateTime.now().add(const Duration(days: 365)),
      ),
      Savings(
        id: 'vacation-savings',
        title: 'Vacation Fund',
        balance: 300,
        target: 1500,
        type: SavingsType.currentSaving,
      ),
      Savings(
        id: 'member-savings',
        title: 'Group Savings',
        balance: 3200,
        target: 5000,
        type: SavingsType.memberSaving,
      ),
    ];

    final totalBalance = allSavings.fold<double>(
      0,
      (sum, s) => sum + s.balance,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Savings',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track progress and keep every goal moving.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.savings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insights_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${allSavings.length} goals • GH₵${totalBalance.toStringAsFixed(0)} saved so far',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withValues(
                          alpha: 0.6,
                        ),
                        indicator: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Goals'),
                          Tab(text: 'Overview'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGoalsTab(theme, allSavings, totalBalance),
                  _buildOverviewTab(theme, allSavings, totalBalance),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsTab(
    ThemeData theme,
    List<Savings> allSavings,
    double totalBalance,
  ) {
    final totalTarget = allSavings.fold<double>(0, (sum, s) => sum + s.target);
    final overallProgress = totalTarget > 0 ? totalBalance / totalTarget : 0.0;
    final filteredGoals = _selectedTypeFilter == null
        ? allSavings
        : allSavings.where((s) => s.type == _selectedTypeFilter).toList();
    final filteredCompletedGoals = filteredGoals
        .where((s) => s.balance >= s.target)
        .length;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final goalCardMinHeight = textScale > 1.2 ? 236.0 : 220.0;
    final sortedGoals = List<Savings>.from(filteredGoals)
      ..sort((a, b) {
        switch (_goalsSort) {
          case GoalsSortOption.closestToGoal:
            final aProgress = a.target > 0 ? a.balance / a.target : 0.0;
            final bProgress = b.target > 0 ? b.balance / b.target : 0.0;
            return bProgress.compareTo(aProgress);
          case GoalsSortOption.highestBalance:
            return b.balance.compareTo(a.balance);
          case GoalsSortOption.newest:
            return b.createdAt.compareTo(a.createdAt);
        }
      });

    String sortLabel() {
      switch (_goalsSort) {
        case GoalsSortOption.closestToGoal:
          return 'Closest to goal';
        case GoalsSortOption.highestBalance:
          return 'Highest balance';
        case GoalsSortOption.newest:
          return 'Newest';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          BalanceCardShell(
            gradientColors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            shadowColor: theme.colorScheme.primary.withOpacitySafe(0.24),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savings Progress',
                            textScaler: const TextScaler.linear(1.0),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${allSavings.length} active goal${allSavings.length > 1 ? 's' : ''}',
                            textScaler: const TextScaler.linear(1.0),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'GH₵${totalBalance.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Overall progress: ${(overallProgress * 100).toStringAsFixed(1)}% • Target: GH₵${totalTarget.toStringAsFixed(0)}',
                          textScaler: const TextScaler.linear(1.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ActionTripleRow(
            deposit: ActionItem(
              label: 'Deposit',
              icon: Icons.add_circle_outline,
              color: theme.colorScheme.primary,
              onTap: () => context.go('/payment'),
              onLongPress: _showSavingsTypeLongPressPicker,
            ),
            withdraw: ActionItem(
              label: 'Withdraw',
              icon: Icons.remove_circle_outline,
              color: theme.colorScheme.error,
              onTap: () => context.go('/savings/withdraw'),
            ),
            transfer: ActionItem(
              label: 'Transfer',
              icon: Icons.swap_horiz_rounded,
              color: const Color(0xFF1B8A9B),
              onTap: () => context.go('/savings/transfer'),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Goals',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showCreateSavingsTypePicker,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('New Goal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Types'),
                    selected: _selectedTypeFilter == null,
                    onSelected: (_) {
                      setState(() => _selectedTypeFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...SavingsType.values.map((type) {
                    final isSelected = _selectedTypeFilter == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(type.icon, size: 16),
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedTypeFilter = isSelected ? null : type;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      theme,
                      icon: Icons.flag_outlined,
                      label: '${filteredGoals.length} goals',
                    ),
                    _buildInfoChip(
                      theme,
                      icon: Icons.check_circle_outline,
                      label: '$filteredCompletedGoals completed',
                      color: theme.colorScheme.primary,
                    ),
                    if (_selectedTypeFilter != null)
                      _buildInfoChip(
                        theme,
                        icon: _selectedTypeFilter!.icon,
                        label: _selectedTypeFilter!.label,
                        color: theme.colorScheme.tertiary,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<GoalsSortOption>(
                tooltip: 'Sort goals',
                onSelected: (value) => setState(() => _goalsSort = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: GoalsSortOption.closestToGoal,
                    child: Text('Closest to goal'),
                  ),
                  PopupMenuItem(
                    value: GoalsSortOption.highestBalance,
                    child: Text('Highest balance'),
                  ),
                  PopupMenuItem(
                    value: GoalsSortOption.newest,
                    child: Text('Newest'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacitySafe(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sortLabel(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(
                'goals-${_goalsSort.name}-${filteredGoals.length}-${_selectedTypeFilter?.name ?? 'all'}',
              ),
              child: filteredGoals.isEmpty
                  ? AppCard(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacitySafe(0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.savings_outlined,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTypeFilter == null
                                  ? 'No savings goals yet'
                                  : 'No ${_selectedTypeFilter!.label.toLowerCase()} goals yet',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTypeFilter == null
                                  ? 'Your savings goals will appear here once they are available for your account.'
                                  : 'Try a different type filter to see more savings goals.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacitySafe(0.65),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  theme,
                                  icon: Icons.flag_outlined,
                                  label: 'Set a target',
                                ),
                                _buildInfoChip(
                                  theme,
                                  icon: Icons.trending_up,
                                  label: 'Track growth',
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  onPressed: _showCreateSavingsTypePicker,
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('New Goal'),
                                ),
                                if (_selectedTypeFilter != null)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(
                                        () => _selectedTypeFilter = null,
                                      );
                                    },
                                    icon: const Icon(Icons.filter_alt_off),
                                    label: const Text('Clear Filter'),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => _tabController.animateTo(1),
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: const Text('Browse Tips'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet =
                            constraints.maxWidth >= Responsive.medium;
                        if (isTablet) {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(sortedGoals.length, (i) {
                              final s = sortedGoals[i];
                              final cardWidth = (constraints.maxWidth - 12) / 2;
                              return SizedBox(
                                width: cardWidth,
                                child: _buildGoalCard(
                                  context,
                                  theme,
                                  s,
                                  goalCardMinHeight,
                                ),
                              );
                            }),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedGoals.length,
                          itemBuilder: (context, i) {
                            final s = sortedGoals[i];
                            return _buildGoalCard(
                              context,
                              theme,
                              s,
                              goalCardMinHeight,
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    ThemeData theme,
    Savings s,
    double goalCardMinHeight,
  ) {
    final progress = (s.balance / s.target).clamp(0.0, 1.0);
    final remaining = (s.target - s.balance).clamp(0.0, double.infinity);
    final isCompleted = s.balance >= s.target;
    final accentColor = _goalAccentColor(theme, s.type);
    final createdLabel =
        '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}';
    final maturityStatusLabel = s.maturityDate == null
        ? null
        : _maturityStatusLabel(s.maturityDate!);
    return AppCard(
      onTap: () => context.go('/savings/${s.id}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacitySafe(0.10),
              accentColor.withOpacitySafe(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacitySafe(0.12)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: goalCardMinHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacitySafe(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.type.icon, color: accentColor, size: 24),
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
                                s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacitySafe(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Completed',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildInfoChip(
                              theme,
                              icon: s.type.icon,
                              label: s.type.label,
                            ),
                            _buildInfoChip(
                              theme,
                              icon: Icons.schedule_outlined,
                              label: 'Created $createdLabel',
                            ),
                          ],
                        ),
                        if (s.type == SavingsType.fixedDeposit &&
                            s.interestRate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${s.interestRate!.toStringAsFixed(2)}% p.a.',
                              textScaler: const TextScaler.linear(1.0),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'GH₵${s.balance.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                      Text(
                        'of GH₵${s.target.toStringAsFixed(0)}',
                        textScaler: const TextScaler.linear(1.0),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted
                            ? 'Goal reached'
                            : '${(progress * 100).toStringAsFixed(0)}% Complete',
                        textScaler: const TextScaler.linear(1.0),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.7,
                          ),
                        ),
                      ),
                      Text(
                        isCompleted
                            ? 'Fully funded'
                            : 'GH₵${remaining.toStringAsFixed(0)} left',
                        textScaler: const TextScaler.linear(1.0),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accentColor,
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
                      backgroundColor: theme.colorScheme.onSurface
                          .withOpacitySafe(0.06),
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (s.maturityDate != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      theme,
                      icon: Icons.calendar_today,
                      label:
                          'Matures ${s.maturityDate!.day}/${s.maturityDate!.month}/${s.maturityDate!.year}',
                      color: theme.colorScheme.secondary,
                    ),
                    if (maturityStatusLabel != null)
                      _buildInfoChip(
                        theme,
                        icon: Icons.timelapse_rounded,
                        label: maturityStatusLabel,
                        color: isCompleted
                            ? accentColor
                            : theme.colorScheme.tertiary,
                      ),
                  ],
                )
              else
                const SizedBox(height: 20),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go('/savings/${s.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'View Details',
                        textScaler: const TextScaler.linear(1.0),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 34,
                    child: isCompleted
                        ? OutlinedButton.icon(
                            onPressed: () => context.go('/savings/${s.id}'),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                            ),
                            label: const Text('Review'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              side: BorderSide(
                                color: accentColor.withOpacitySafe(0.35),
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () => context.go('/payment'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Deposit'),
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
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
    final overallProgress = totalTarget > 0
        ? (totalBalance / totalTarget).clamp(0.0, 1.0)
        : 0.0;
    final closestGoal = allSavings.isEmpty
        ? null
        : (List<Savings>.from(allSavings)..sort((a, b) {
                final bRate = b.target > 0 ? b.balance / b.target : 0.0;
                final aRate = a.target > 0 ? a.balance / a.target : 0.0;
                return bRate.compareTo(aRate);
              }))
              .first;
    final closestProgress = closestGoal != null && closestGoal.target > 0
        ? (closestGoal.balance / closestGoal.target).clamp(0.0, 1.0)
        : 0.0;

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
          // Premium Overview Hero
          BalanceCardShell(
            gradientColors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            shadowColor: theme.colorScheme.primary.withOpacitySafe(0.24),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savings Overview',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${allSavings.length} active goal${allSavings.length > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'GH₵${totalBalance.toStringAsFixed(2)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Progress',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${(overallProgress * 100).toStringAsFixed(0)}%  of  GH₵${totalTarget.toStringAsFixed(0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Overview Stats',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'GH₵${totalInterest.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Est. Interest',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 12),
                      Text(
                        'GH₵${(totalTarget - totalBalance).toStringAsFixed(0)}',
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
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.donut_large,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Savings Rate',
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

          if (closestGoal != null) ...[
            AppCard(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacitySafe(
                        0.6,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Closest to Goal',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacitySafe(
                              0.55,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          closestGoal.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: closestProgress,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.onSurface
                                .withOpacitySafe(0.08),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(closestProgress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Savings Breakdown by Type
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: true,
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
                                        'GH₵${balance.toStringAsFixed(2)}',
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

  Color _goalAccentColor(ThemeData theme, SavingsType type) {
    switch (type) {
      case SavingsType.memberSaving:
        return theme.colorScheme.primary;
      case SavingsType.currentSaving:
        return theme.colorScheme.secondary;
      case SavingsType.kiddySaving:
        return theme.colorScheme.tertiary;
      case SavingsType.fixedDeposit:
        return theme.colorScheme.error;
    }
  }

  String _maturityStatusLabel(DateTime maturityDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      maturityDate.year,
      maturityDate.month,
      maturityDate.day,
    );
    final daysLeft = target.difference(today).inDays;

    if (daysLeft < 0) {
      return 'Matured';
    }
    if (daysLeft == 0) {
      return 'Matures today';
    }
    if (daysLeft == 1) {
      return '1 day left';
    }
    return '$daysLeft days left';
  }

  Widget _buildInfoChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacitySafe(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipColor.withOpacitySafe(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
                  color: color.withOpacitySafe(0.1),
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
                            color: color.withOpacitySafe(0.1),
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
                            color: color.withOpacitySafe(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap for details',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color.withOpacitySafe(0.6),
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
                            color: tip.color.withOpacitySafe(0.1),
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
                                  color: tip.color.withOpacitySafe(0.1),
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
                          color: tip.color.withOpacitySafe(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tip.color.withOpacitySafe(0.3),
                          ),
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
                                  color: tip.color.withOpacitySafe(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: tip.color.withOpacitySafe(0.5),
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
                                  color: theme.colorScheme.outline
                                      .withOpacitySafe(0.2),
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
}
