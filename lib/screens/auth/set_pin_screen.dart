import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/secure_auth_storage.dart';

class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({
    super.key,
    this.phoneNumber = '',
    this.accountNumber = '',
    this.mode = 'manage',
  });

  final String phoneNumber;
  final String accountNumber;
  final String mode;

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _currentPinController = TextEditingController();
  bool _showPin = false;
  bool _isSubmitting = false;

  bool get _isRegisterMode => widget.mode == 'register';
  bool get _isSignInMode => widget.mode == 'signin';
  bool get _isChangeMode => widget.mode == 'change';

  bool _isFourDigitPin(String value) => RegExp(r'^\d{4}$').hasMatch(value);

  bool get _canSubmit =>
      _isFourDigitPin(_pinController.text.trim()) &&
      (!_isChangeMode || _isFourDigitPin(_currentPinController.text)) &&
      (_isSignInMode || _pinController.text == _confirmController.text);

  bool get _pinMatch =>
      _isSignInMode || _pinController.text == _confirmController.text;

  Future<void> _handleSubmit() async {
    if (_isSubmitting || !_canSubmit) return;

    setState(() => _isSubmitting = true);
    try {
      final pin = _pinController.text.trim();
      final router = GoRouter.of(context);

      if (_isRegisterMode) {
        final accountNumber = widget.accountNumber.isNotEmpty
            ? widget.accountNumber
            : ref.read(authProvider).userId ?? '';
        if (accountNumber.isEmpty) {
          throw ValidationException(
            message: 'Missing account details. Please restart registration.',
          );
        }
        await ref
            .read(authProvider.notifier)
            .setPin(userId: accountNumber, pin: pin);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('PIN Created'),
            content: Text(
              'Your mobile banking PIN has been created successfully. '
              'You can now sign in with your phone number and PIN.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  router.go('/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
        return;
      }

      if (_isChangeMode) {
        if (_currentPinController.text.length != 4) {
          throw ValidationException(message: 'Enter your current 4-digit PIN.');
        }
        await ref
            .read(authProvider.notifier)
            .changePin(currentPin: _currentPinController.text, newPin: pin);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN changed successfully.')),
        );
        router.go('/settings');
        return;
      }

      if (_isSignInMode) {
        if (widget.phoneNumber.isEmpty || widget.accountNumber.isEmpty) {
          throw ValidationException(
            message: 'Missing sign-in details. Please restart login.',
          );
        }

        await ref
            .read(authProvider.notifier)
            .signInWithPin(
              phoneNumber: widget.phoneNumber,
              accountNumber: widget.accountNumber,
              pin: pin,
            );

        ref.invalidate(userProfileProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(loansProvider);
        ref.invalidate(savingsProvider);

        if (!mounted) return;
        router.go('/activity');
        return;
      }

      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.userId != null) {
        await ref
            .read(authProvider.notifier)
            .setPin(userId: authState.userId!, pin: pin);
      }

      await SecureAuthStorage.instance.storePin(pin);

      ref.invalidate(userProfileProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(loansProvider);
      ref.invalidate(savingsProvider);

      if (!mounted) return;
      router.go('/activity');
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to set PIN right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

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
                      const SizedBox(height: 24),
                      Text(
                        _isRegisterMode
                            ? 'Create PIN'
                            : (_isSignInMode
                                  ? 'Enter PIN'
                                  : (_isChangeMode
                                        ? 'Change PIN'
                                        : 'Update PIN')),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRegisterMode
                            ? 'Create a 4-digit PIN to secure your account'
                            : (_isSignInMode
                                  ? 'Enter your 4-digit PIN to sign in'
                                  : (_isChangeMode
                                        ? 'Verify your current PIN before choosing a new one'
                                        : 'Set a new 4-digit PIN for your account')),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // PIN Card
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
                            if (_isChangeMode) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current PIN',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _currentPinController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    obscureText: true,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 8,
                                        ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: '••••',
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
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security PIN',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pinController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  obscureText: !_showPin,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 8,
                                      ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: '••••',
                                    hintStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.white54),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPin
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () =>
                                          setState(() => _showPin = !_showPin),
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
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                            if (!_isSignInMode) ...[
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Confirm PIN',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _confirmController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    obscureText: !_showPin,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 8,
                                        ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: '••••',
                                      hintStyle: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.white54),
                                      filled: true,
                                      fillColor: Colors.white.withOpacitySafe(
                                        0.15,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color:
                                              _pinMatch ||
                                                  _confirmController
                                                      .text
                                                      .isEmpty
                                              ? Colors.white.withOpacitySafe(
                                                  0.2,
                                                )
                                              : Colors.red.withOpacitySafe(0.5),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color:
                                              _pinMatch ||
                                                  _confirmController
                                                      .text
                                                      .isEmpty
                                              ? Colors.white.withOpacitySafe(
                                                  0.2,
                                                )
                                              : Colors.red.withOpacitySafe(0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: _pinMatch
                                              ? Colors.white
                                              : Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  if (_confirmController.text.isNotEmpty &&
                                      !_pinMatch)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'PINs do not match',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.red[300]),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _canSubmit && !_isSubmitting
                                    ? _handleSubmit
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _canSubmit && !_isSubmitting
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
                                        _isRegisterMode
                                            ? 'Register'
                                            : (_isSignInMode
                                                  ? 'Sign In'
                                                  : 'Save PIN'),
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: _canSubmit
                                                  ? primary
                                                  : Colors.white60,
                                            ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
