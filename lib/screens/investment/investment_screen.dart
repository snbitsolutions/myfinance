import 'package:flutter/material.dart';

import 'investments_screen.dart';

/// Legacy route retained for compatibility with existing navigation links.
class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) => const InvestmentsScreen();
}
