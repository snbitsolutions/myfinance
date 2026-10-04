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
    required VoidCallback onTap,
    required ThemeData theme,
    bool isPrimary = false,
    bool emphasizeTitle = false,
  }) {
    final cardColor = isPrimary
        ? const Color(0xFFF8FFFA)
        : Colors.white.withOpacitySafe(0.92);
    final borderColor = isPrimary
        ? const Color(0xFFBEE9CE)
        : const Color(0xFFD7E9DF);
    final iconBg = isPrimary
        ? const Color(0xFFDFF6E9)
        : const Color(0xFFEAF6EF);
    final contentColor = const Color(0xFF0E3A30);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isPrimary ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (isPrimary)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: contentColor,
                        fontWeight: isPrimary || emphasizeTitle
                            ? FontWeight.w800
                            : FontWeight.w700,
                        fontSize: isPrimary ? 16 : 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionContent(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacitySafe(0.96),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F6ED),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'images/adepa_teachers_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Choose an account option',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0E3A30),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose one option below. You will only need to complete the steps for your situation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5B7A6A),
                ),
              ),
              if (widget.reason == 'not_registered') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F4E8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB9E3C8)),
                  ),
                  child: Text(
                    "We couldn't find an account for those details. Choose the option that matches your situation below.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF174B36),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildSelectionCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'I have an account',
                onTap: _handleExistingMemberSelection,
                theme: theme,
                isPrimary: true,
              ),
              const SizedBox(height: 14),
              _buildSelectionCard(
                icon: Icons.person_add_alt_1_rounded,
                title: 'I need a new account',
                onTap: _handleNewMemberSelection,
                theme: theme,
                emphasizeTitle: true,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Already enrolled for mobile banking? Sign in',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1D7A52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
    final body = _buildSelectionContent(theme);

    return Scaffold(
      backgroundColor: secondary,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E8B57), Color(0xFF0E8F87), Color(0xFF1F5F3F)],
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
