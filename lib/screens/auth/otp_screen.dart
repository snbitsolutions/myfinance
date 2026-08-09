import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/models/notification_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.accountNumber,
  });

  final String phoneNumber;
  final String accountNumber;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isValid => _otpController.text.trim().length == 4;

  String get _normalizedOtp => _otpController.text.trim();

  Future<void> _handleVerify() async {
    if (_isSubmitting || !_isValid) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .loginWithOtp(
            phoneNumber: widget.phoneNumber,
            accountNumber: widget.accountNumber,
            otp: _normalizedOtp,
          );
      await NotificationService.instance.addNotification(
        AppNotification(
          id: 'otp_verified_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Verification complete',
          message:
              'Your OTP was verified successfully for ${widget.phoneNumber}.',
          timestamp: DateTime.now(),
          type: AppNotificationType.security,
          read: false,
        ),
      );
      ref.invalidate(userProfileProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(loansProvider);
      ref.invalidate(savingsProvider);
      if (!mounted) return;
      context.go('/home');
    } on AppException catch (e) {
      await NotificationService.instance.addNotification(
        AppNotification(
          id: 'otp_failed_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Verification issue',
          message: 'We could not verify the OTP for ${widget.phoneNumber}.',
          timestamp: DateTime.now(),
          type: AppNotificationType.security,
          read: false,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      await NotificationService.instance.addNotification(
        AppNotification(
          id: 'otp_failed_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Verification issue',
          message: 'We could not verify the OTP for ${widget.phoneNumber}.',
          timestamp: DateTime.now(),
          type: AppNotificationType.security,
          read: false,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter OTP',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A 4-digit code was sent to ${widget.phoneNumber}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // OTP Card
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
                                  'Verification Code',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 12,
                                      ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: '0000',
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
                                  onSubmitted: (_) => _handleVerify(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isValid && !_isSubmitting
                                    ? _handleVerify
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
                                        'Verify & Sign In',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: _isValid
                                                  ? primary
                                                  : Colors.white60,
                                            ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(
                                'Use a different number',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
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
