import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _bioAuth = false;
  String _currency = AppConstants.currencyCode;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings Section
            _buildSectionTitle(context, 'Account', Icons.person),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'steven@email.com',
                    onTap: () => _showEditDialog(context, 'Email Address'),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.phone,
                    title: 'Phone Number',
                    subtitle: '0241234567',
                    onTap: () => _showEditDialog(context, 'Phone Number'),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Full Name',
                    subtitle: 'Steven Boadu',
                    onTap: () => _showEditDialog(context, 'Full Name'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            _buildSectionTitle(context, 'Preferences', Icons.tune),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: _language,
                    onTap: () => _showLanguageDialog(context),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.5),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.attach_money,
                    title: 'Currency',
                    subtitle: _currency,
                    onTap: () => _showCurrencyDialog(context),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withOpacitySafe(0.5),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSwitchTile(
                    context,
                    icon: Icons.notifications_active,
                    title: 'Notifications',
                    subtitle: 'Receive transaction alerts',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security Section
            _buildSectionTitle(context, 'Security', Icons.security),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.lock,
                    title: 'PIN',
                    subtitle: 'Change your PIN',
                    onTap: () => context.go('/set-pin'),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.password,
                    title: 'Password',
                    subtitle: 'Change your password',
                    onTap: () => _showEditDialog(context, 'Password'),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSwitchTile(
                    context,
                    icon: Icons.fingerprint,
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face ID',
                    value: _bioAuth,
                    onChanged: (value) {
                      setState(() => _bioAuth = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support Section
            _buildSectionTitle(context, 'Support', Icons.help),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    subtitle: 'Get answers to common questions',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Contact Support',
                    subtitle: 'Chat with our support team',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.bug_report_outlined,
                    title: 'Report an Issue',
                    subtitle: 'Help us improve the app',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle(context, 'About', Icons.info),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.outline.withOpacitySafe(0.2),
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'v${AppConstants.appVersion}',
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            AppCard(
              margin: EdgeInsets.zero,
              backgroundColor: theme.colorScheme.error.withOpacitySafe(0.1),
              child: _buildSettingTile(
                context,
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                titleColor: theme.colorScheme.error,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacitySafe(0.1),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? titleColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: titleColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                      ),
                    ),
                ],
              ),
            ),
            trailing ?? const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String fieldName) {
    final theme = Theme.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter your $fieldName',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$fieldName updated successfully'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile('English', 'English'),
            _buildRadioTile('Español', 'Spanish'),
            _buildRadioTile('Français', 'French'),
            _buildRadioTile('Deutsch', 'German'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _language = 'English');
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile('GH₵ GHS', 'GHS'),
            _buildRadioTile('\$ USD', 'USD'),
            _buildRadioTile('€ EUR', 'EUR'),
            _buildRadioTile('£ GBP', 'GBP'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currency = 'GHS');
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppConstants.appName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Version ${AppConstants.appVersion}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Smart Finance, Smart Future',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'A mobile app for personal finance management, featuring loan applications, savings tracking, and payment processing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildRadioTile(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _currency,
            onChanged: (value) {
              if (value != null) {
                setState(() => _currency = value);
              }
            },
            activeColor: theme.colorScheme.primary,
          ),
          Text(label),
        ],
      ),
    );
  }
}
