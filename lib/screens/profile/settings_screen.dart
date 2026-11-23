// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_card.dart';
import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/layout/responsive.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_service.dart';
import '../../core/services/device_identity_service.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/secure_auth_storage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoggingOut = false;
  bool _notificationsEnabled = true;
  bool _bioAuth = false;
  String _currency = AppConstants.currencyCode;
  String _language = 'English';
  late final Future<_DeviceSecurityDetails> _deviceSecurityFuture;
  final _notificationService = NotificationService.instance;
  final _biometricAuthService = BiometricAuthService();
  final _authService = AuthService();
  final TextEditingController _deleteAccountOtpController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _deviceSecurityFuture = _loadDeviceSecurityDetails();
    _loadNotificationPreferences();
    _loadBiometricPreference();
  }

  @override
  void dispose() {
    _deleteAccountOtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Settings',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= Responsive.medium;

          // Build section groups as named widgets
          final accountSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Account', Icons.person),
              AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingTile(
                      context,
                      icon: Icons.email,
                      title: 'Email',
                      subtitle: 'Unavailable from the customer API',
                      onTap: () => _showUnavailableProfileEditDialog(context),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacitySafe(0.2),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.phone,
                      title: 'Phone Number',
                      subtitle: 'Managed by account registration',
                      onTap: () => _showUnavailableProfileEditDialog(context),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacitySafe(0.2),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Full Name',
                      subtitle: 'Unavailable from the customer API',
                      onTap: () => _showUnavailableProfileEditDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );

          final securitySection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'Security', Icons.security),
              AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingTile(
                      context,
                      icon: Icons.lock,
                      title: 'PIN / Password',
                      subtitle: 'Change your 4-digit security PIN',
                      onTap: () => context.go('/set-pin?mode=change'),
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
                      onChanged: _handleBiometricToggle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<_DeviceSecurityDetails>(
                future: _deviceSecurityFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return AppCard(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Loading device security details...',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return AppCard(
                      margin: EdgeInsets.zero,
                      child: _buildSettingTile(
                        context,
                        icon: Icons.phonelink_lock,
                        title: 'Device Security',
                        subtitle: 'Device details are unavailable right now',
                      ),
                    );
                  }

                  final details = snapshot.data!;
                  return AppCard(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingTile(
                          context,
                          icon: Icons.phonelink_lock,
                          title: 'Masked Device ID',
                          subtitle: details.maskedInstallationId,
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(0.2),
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.verified_user,
                          title: 'Session Binding',
                          subtitle: details.sessionBindingLabel,
                          trailing: Icon(
                            details.sessionBound
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: details.sessionBound
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(0.2),
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.lock_person,
                          title: 'Secure Token Vault',
                          subtitle: 'Enabled for login and refresh tokens',
                          trailing: Icon(
                            Icons.lock,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withOpacitySafe(0.2),
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.devices,
                          title: details.deviceModel,
                          subtitle: details.platformSummary,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );

          final logoutSection = AppCard(
            margin: EdgeInsets.zero,
            child: _isLoggingOut
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Signing out…'),
                      ],
                    ),
                  )
                : _buildSettingTile(
                    context,
                    icon: Icons.logout,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account on this device',
                    onTap: _handleLogout,
                  ),
          );

          final dangerSection = Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  theme.colorScheme.error.withOpacitySafe(0.1),
                  theme.colorScheme.error.withOpacitySafe(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.error.withOpacitySafe(0.22),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacitySafe(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Permanently delete your account and related data',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showDeleteAccountDialog(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          final preferencesSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      subtitle: 'Enable alerts across the app',
                      value: _notificationsEnabled,
                      onChanged: _handleNotificationToggle,
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacitySafe(0.2),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.notifications_none_outlined,
                      title: 'Notification Center',
                      subtitle: 'Manage alerts, reminders, and unread updates',
                      onTap: () => context.go('/notifications'),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );

          final supportSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      subtitle: AppConstants.supportPhoneNumber,
                      onTap: () => _showSupportContact(context),
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
            ],
          );

          final aboutSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, 'About', Icons.info),
              AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingTile(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      onTap: () => context.go('/terms?viewOnly=true'),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacitySafe(0.2),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'How we handle your information',
                      onTap: () => context.go('/privacy-policy'),
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
            ],
          );

          if (isTablet) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        accountSection,
                        securitySection,
                        logoutSection,
                        const SizedBox(height: 12),
                        dangerSection,
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        preferencesSection,
                        supportSection,
                        aboutSection,
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                accountSection,
                preferencesSection,
                securitySection,
                supportSection,
                aboutSection,
                logoutSection,
                const SizedBox(height: 12),
                dangerSection,
                const SizedBox(height: 32),
              ],
            ),
          );
        },
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

  void _showUnavailableProfileEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profile editing unavailable'),
        content: const Text(
          'The current customer API does not document profile update endpoints. No account details were changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
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

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    _deleteAccountOtpController.clear();
    late String requestId;
    final imeiNumber = await DeviceIdentityService().getBackendDeviceNumber();

    final shouldStartDeletion = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action permanently deletes your account and related local session data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldStartDeletion != true || !mounted) return;

    try {
      final requestResponse = await _authService.requestAccountDeletion(
        imeiNumber: imeiNumber,
      );
      requestId = requestResponse['request_id']?.toString() ?? '';
      if (requestId.isEmpty) {
        throw ValidationException(
          message: 'The deletion request did not return a valid request ID.',
        );
      }

      final otp = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Verify deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the 4-digit code sent to your registered device.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deleteAccountOtpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _deleteAccountOtpController.text.trim(),
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      );

      if (otp == null || otp.isEmpty || !mounted) return;
      await _authService.verifyAccountDeletionOtp(
        requestId: requestId,
        otp: otp,
      );

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm account deletion'),
          content: const Text(
            'This final step deletes your account permanently. Confirm to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete account'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
      await _authService.deleteAccount(
        requestId: requestId,
        imeiNumber: imeiNumber,
      );

      final secureStorage = SecureAuthStorage.instance;
      await secureStorage.clearAuthSecrets();
      await SharedPreferences.getInstance().then((prefs) => prefs.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );
      context.go('/login');
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete your account right now.'),
        ),
      );
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showSupportContact(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Call support: ${AppConstants.supportPhoneNumber}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotificationPreferences() async {
    final preferences = await _notificationService.getPreferences();
    if (!mounted) return;
    setState(() => _notificationsEnabled = preferences.enabled);
  }

  Future<void> _loadBiometricPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled =
        preferences.getBool(AppConstants.sharedPrefKeyBiometricAuth) ?? false;
    if (!mounted) return;
    setState(() => _bioAuth = enabled);
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (value && !await _biometricAuthService.isAvailable()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric authentication is not available on this device.',
          ),
        ),
      );
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(AppConstants.sharedPrefKeyBiometricAuth, value);
    if (!mounted) return;
    setState(() => _bioAuth = value);
  }

  Future<void> _handleNotificationToggle(bool value) async {
    final preferences = await _notificationService.getPreferences();
    await _notificationService.savePreferences(
      preferences.copyWith(enabled: value),
    );
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
  }

  Widget _buildRadioTile(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RadioGroup<String>(
        groupValue: _currency,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _currency = value);
        },
        child: Row(
          children: [
            Radio<String>(value: value, activeColor: theme.colorScheme.primary),
            Text(label),
          ],
        ),
      ),
    );
  }

  Future<_DeviceSecurityDetails> _loadDeviceSecurityDetails() async {
    final deviceIdentityService = DeviceIdentityService();
    final identity = await deviceIdentityService.collectIdentity();
    final fingerprint =
        identity['installation_fingerprint'] as String? ??
        await deviceIdentityService.getInstallationFingerprint();
    final sessionBound = await SecureAuthStorage.instance
        .hasSessionBoundToFingerprint(fingerprint);
    final manufacturer = identity['manufacturer'] as String? ?? 'Unknown';
    final osVersion = identity['os_version'] as String? ?? 'Unknown OS';

    return _DeviceSecurityDetails(
      maskedInstallationId:
          identity['installation_id_masked'] as String? ??
          await deviceIdentityService.getMaskedInstallationId(),
      sessionBound: sessionBound,
      sessionBindingLabel: sessionBound
          ? 'Bound to ${DeviceIdentityService.shortenFingerprint(fingerprint)}'
          : 'No active session is bound to this device',
      deviceModel: identity['device_model'] as String? ?? 'Current device',
      platformSummary: '$manufacturer • $osVersion',
    );
  }
}

class _DeviceSecurityDetails {
  const _DeviceSecurityDetails({
    required this.maskedInstallationId,
    required this.sessionBound,
    required this.sessionBindingLabel,
    required this.deviceModel,
    required this.platformSummary,
  });

  final String maskedInstallationId;
  final bool sessionBound;
  final String sessionBindingLabel;
  final String deviceModel;
  final String platformSummary;
}
