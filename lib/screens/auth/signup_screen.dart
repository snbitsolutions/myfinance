import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/color_ext.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.reason});

  final String? reason;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  void _handleNewMemberSelection() {
    context.go('/existing-member-enrollment?memberType=new');
  }

  void _handleExistingMemberSelection() {
    context.go('/existing-member-enrollment?memberType=existing');
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isPrimary = false,
  }) {
    final cardColor = isPrimary
        ? Colors.white.withOpacitySafe(0.18)
        : Colors.white.withOpacitySafe(0.08);
    final borderColor = isPrimary
        ? Colors.white.withOpacitySafe(0.35)
        : Colors.white.withOpacitySafe(0.18);
    final iconBg = isPrimary
        ? Colors.white.withOpacitySafe(0.16)
        : Colors.white.withOpacitySafe(0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isPrimary ? Colors.white70 : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionContent(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create account',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your account type',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        if (widget.reason == 'not_registered') ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacitySafe(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacitySafe(0.30)),
            ),
            child: Text(
              "We couldn't find your account. Please register to continue.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildSelectionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Existing member',
          subtitle: 'Continue with your current account.',
          onTap: _handleExistingMemberSelection,
          theme: theme,
          isPrimary: true,
        ),
        const SizedBox(height: 14),
        _buildSelectionCard(
          icon: Icons.person_add_alt_1_rounded,
          title: 'New member',
          subtitle: 'Open a new account with your details.',
          onTap: _handleNewMemberSelection,
          theme: theme,
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'Already registered? Sign in',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final primary = theme.colorScheme.primary;
    final body = _buildSelectionContent(theme);

    return Scaffold(
      backgroundColor: secondary,
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
