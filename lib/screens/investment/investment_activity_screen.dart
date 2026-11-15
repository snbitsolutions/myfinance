import 'package:flutter/material.dart';

import 'investments_screen.dart';

/// Legacy route retained until the investment service exposes activity data.
class InvestmentActivityScreen extends StatelessWidget {
  const InvestmentActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => const InvestmentsScreen();
}
