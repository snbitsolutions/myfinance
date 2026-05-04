import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_flow_error_utils.dart';
import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/providers/app_providers.dart';

class AccountNumberScreen extends ConsumerStatefulWidget {
  const AccountNumberScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<AccountNumberScreen> createState() =>
      _AccountNumberScreenState();
}

class _AccountNumberScreenState extends ConsumerState<AccountNumberScreen> {
  final TextEditingController _accountController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isValid => _accountController.text.trim().length >= 8;

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authProvider.notifier).confirmAccountNumber(
            phoneNumber: widget.phoneNumber,
            accountNumber: _accountController.text.trim(),
          );
      if (!mounted) return;
      context.go(
        '/otp',
        extra: {
          'phoneNumber': widget.phoneNumber,
          'accountNumber': _accountController.text.trim(),
        },
      );
    } on AppException catch (e) {
      if (!mounted) return;
      if (shouldRedirectToSignup(e.message)) {
        context.go('/signup?reason=not_registered');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to confirm account number.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
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
                  const SizedBox(height: 12),
                  Text(
                    'Sign in',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the account number linked to ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Number',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _accountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.credit_card_outlined,
                              color: Colors.white70,
                            ),
                            hintText: 'Enter your account number',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white54,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacitySafe(0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacitySafe(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacitySafe(0.2),
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
                          style: const TextStyle(color: Colors.white),
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
                                    'Send OTP',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: _isValid
                                          ? primary
                                          : Colors.white60,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}