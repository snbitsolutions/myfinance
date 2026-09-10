import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_flow_error_utils.dart';
import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _showSnbReveal = false;
  bool _isSubmitting = false;

  bool get _isValid => _phoneController.text.trim().length >= 9;

  String get _normalizedPhoneNumber {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    // The documented OTP endpoint expects Ghana's international format.
    if (digits.startsWith('233')) return digits;
    if (digits.startsWith('0') && digits.length == 10) {
      return '233${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _showSnbSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SnbITSolutionsSheet(),
    );
  }

  Future<void> _handleSnbTap() async {
    if (_showSnbReveal) return;
    setState(() => _showSnbReveal = true);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await _showSnbSheet();
    if (!mounted) return;
    setState(() => _showSnbReveal = false);
  }

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .confirmPhoneNumber(phoneNumber: _normalizedPhoneNumber);

      final prefs = await SharedPreferences.getInstance();
      final storedAccountNumber =
          prefs.getString(AppConstants.sharedPrefKeyUserId)?.trim() ?? '';
      final fallbackAccountNumber = storedAccountNumber.isNotEmpty
          ? storedAccountNumber
          : _normalizedPhoneNumber.replaceAll(RegExp(r'\D'), '');

      await ref
          .read(authProvider.notifier)
          .sendLoginOtp(
            phoneNumber: _normalizedPhoneNumber,
            accountNumber: fallbackAccountNumber,
          );

      await prefs.setString(
        AppConstants.sharedPrefKeyUserEmail,
        _normalizedPhoneNumber,
      );
      await prefs.setString(
        AppConstants.sharedPrefKeyUserId,
        fallbackAccountNumber,
      );
      if (!mounted) return;
      context.go(
        '/otp',
        extra: {
          'phoneNumber': _normalizedPhoneNumber,
          'accountNumber': fallbackAccountNumber,
        },
      );
    } on AppException catch (e) {
      if (!mounted) return;
      if (shouldRedirectToSignup(e.message)) {
        context.go('/signup?reason=not_registered');
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to confirm phone number.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: secondary,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Decorative spheres
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacitySafe(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  left: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacitySafe(0.08),
                    ),
                  ),
                ),
                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 320),
                          height: 142,
                          child: Image.asset(
                            'images/adepa_teachers_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome back',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Login Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacitySafe(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phone Number',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                        color: Colors.white70,
                                      ),
                                      hintText: '+233 50 xxx xxxx',
                                      hintStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white54),
                                      filled: true,
                                      fillColor: Colors.white.withOpacitySafe(
                                        0.15,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacitySafe(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacitySafe(
                                            0.2,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isValid && !_isSubmitting
                                      ? _handleContinue
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isValid && !_isSubmitting
                                        ? Colors.white
                                        : Colors.white.withOpacitySafe(0.3),
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  primary,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Continue',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: _isValid
                                                    ? primary
                                                    : Colors.white60,
                                              ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                      TextButton(
                                        onPressed: () => context.go('/signup'),
                                        child: Text(
                                          'Sign up',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: IgnorePointer(
                      child: AnimatedSlide(
                        offset: _showSnbReveal
                            ? Offset.zero
                            : const Offset(0, 0.18),
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: AnimatedOpacity(
                          opacity: _showSnbReveal ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacitySafe(0.12),
                                    Colors.white.withOpacitySafe(0.04),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacitySafe(0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacitySafe(0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.code_rounded,
                                      size: 14,
                                      color: Colors.white.withOpacitySafe(0.84),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Powered by SNB IT Solutions',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.white.withOpacitySafe(
                                              0.84,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.35,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 76,
                      child: GestureDetector(
                        onTap: _handleSnbTap,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SnbITSolutionsSheet extends StatelessWidget {
  const _SnbITSolutionsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacitySafe(0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacitySafe(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            Text(
              'SNB IT Solutions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crafting smart digital experiences\nfor Africa\'s financial future.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: theme.colorScheme.outline.withOpacitySafe(0.15),
              thickness: 1,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, size: 16, color: primary),
                const SizedBox(width: 6),
                Text(
                  'Powering ${AppConstants.appName}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 SNB IT Solutions. All rights reserved.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
