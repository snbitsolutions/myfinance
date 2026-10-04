import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_flow_error_utils.dart';
import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../router/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showSnbReveal = false;
  int _snbTapCount = 0;
  bool _isSubmitting = false;
  bool _biometricEnabled = false;
  bool _obscurePassword = true;
  final _biometricAuthService = BiometricAuthService();

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  bool get _isValid {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return phoneDigits.length >= 9 &&
        _passwordController.text.trim().isNotEmpty;
  }

  String get _normalizedPhoneNumber {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
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
    _snbTapCount++;
    if (_snbTapCount < 10) return;

    _snbTapCount = 0;
    setState(() => _showSnbReveal = true);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await _showSnbSheet();
    if (!mounted) return;
    setState(() => _showSnbReveal = false);
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting || !_isValid) return;

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.sharedPrefKeyDebugBypassAuth, false);
      await ref
          .read(authProvider.notifier)
          .login(
            phoneNumber: _normalizedPhoneNumber,
            password: _passwordController.text,
          );
      if (!mounted) return;

      AppRouter.invalidateSessionCache();
      context.go('/home');
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
        const SnackBar(content: Text('Unable to sign in. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleBiometricSignIn() async {
    if (_isSubmitting) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(AppConstants.sharedPrefKeyBiometricAuth) ?? false;
    if (!enabled) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (!await _biometricAuthService.authenticate()) return;
      if (!await ref
          .read(authProvider.notifier)
          .restoreStoredSessionAfterBiometric()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your saved session is unavailable. Please sign in again.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      // The router may have cached the unauthenticated result while this
      // screen was open. Re-check the newly restored secure session.
      AppRouter.invalidateSessionCache();
      context.go('/home');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _biometricEnabled =
          prefs.getBool(AppConstants.sharedPrefKeyBiometricAuth) ?? false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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
                        GestureDetector(
                          onTap: _handleSnbTap,
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 320),
                            height: 142,
                            child: Image.asset(
                              'images/adepa_teachers_logo.png',
                              fit: BoxFit.contain,
                            ),
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Phone Number',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      if (_biometricEnabled)
                                        Tooltip(
                                          message: 'Use biometric sign-in',
                                          child: Container(
                                            width: 42,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacitySafe(0.55),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              onPressed: _isSubmitting
                                                  ? null
                                                  : _handleBiometricSignIn,
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.fingerprint,
                                                size: 22,
                                              ),
                                              color: Colors.white,
                                              disabledColor: Colors.white54,
                                              tooltip: 'Use biometric sign-in',
                                            ),
                                          ),
                                        ),
                                    ],
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
                                  const SizedBox(height: 16),
                                  Text(
                                    'Password',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                        color: Colors.white70,
                                      ),
                                      hintText: 'Enter your password',
                                      hintStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white54),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white70,
                                        ),
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                      ),
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
                                      ? _handleLogin
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
                                          'Sign in',
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
      margin: const EdgeInsets.symmetric(horizontal: 52, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacitySafe(0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
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
            const SizedBox(height: 6),
            Image.asset(
              'images/snb_it_solutions_logo.png',
              width: 120,
              height: 54,
              fit: BoxFit.contain,
            ),
            Text(
              'www.snbitsolutions.com',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Divider(
              color: theme.colorScheme.outline.withOpacitySafe(0.15),
              thickness: 1,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_outlined, size: 14, color: primary),
                const SizedBox(width: 4),
                Text(
                  '+233 57 225 8441',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
