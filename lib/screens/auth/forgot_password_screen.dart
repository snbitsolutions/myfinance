import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/color_ext.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/services/api_service.dart';
import '../../core/services/device_identity_service.dart';

enum _ResetStep { account, otp, password }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final DeviceIdentityService _deviceIdentityService = DeviceIdentityService();

  _ResetStep _step = _ResetStep.account;
  bool _isSubmitting = false;
  String? _requestId;

  bool get _isAccountNumberValid {
    final digits = _accountNumberController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 5;
  }

  bool get _isOtpValid {
    return _otpController.text.trim().length >= 4;
  }

  bool get _isPasswordValid {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    return newPassword.length >= 6 && newPassword == confirmPassword;
  }

  String get _normalizedAccountNumber {
    return _accountNumberController.text.replaceAll(RegExp(r'\D'), '');
  }

  String _maskedAccountNumber() {
    final digits = _normalizedAccountNumber;
    if (digits.isEmpty) return 'your account';
    if (digits.length <= 4) return digits;
    return '••••${digits.substring(digits.length - 4)}';
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestResetCode() async {
    if (!_isAccountNumberValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid account number to reset your password.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final imeiNumber = await _deviceIdentityService.getBackendDeviceNumber();
      final response = await _authService.requestPasswordReset(
        accountNumber: _normalizedAccountNumber,
        imeiNumber: imeiNumber,
      );
      final requestId = response['request_id']?.toString();
      if (requestId == null || requestId.isEmpty) {
        throw ValidationException(
          message: 'Reset request did not return a valid request ID.',
        );
      }

      if (!mounted) return;
      setState(() {
        _requestId = requestId;
        _step = _ResetStep.otp;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A reset code was sent for account ${_maskedAccountNumber()}.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send a password reset request right now.'),
        ),
      );
    } finally {
      if (mounted && _step != _ResetStep.otp) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_requestId == null || !_isOtpValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 4-digit verification code sent to you.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authService.verifyPasswordResetOtp(
        requestId: _requestId!,
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _step = _ResetStep.password;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification confirmed. Set your new password.'),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify the reset code.')),
      );
    } finally {
      if (mounted && _step != _ResetStep.password) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_requestId == null || !_isPasswordValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a stronger password and confirm it exactly.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final imeiNumber = await _deviceIdentityService.getBackendDeviceNumber();
      await _authService.passwordReset(
        requestId: _requestId!,
        newPassword: _newPasswordController.text.trim(),
        imeiNumber: imeiNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully.')),
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
          content: Text('Unable to reset your password right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildAccountStep(ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Forgot password?',
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter your account number and we’ll send a secure reset code to continue.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacitySafe(0.85),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Account number',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.numbers_outlined,
              color: Colors.white70,
            ),
            hintText: 'Account number (at least 5 digits)',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white54,
            ),
            filled: true,
            fillColor: Colors.white.withOpacitySafe(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_isAccountNumberValid && !_isSubmitting)
                ? _handleRequestResetCode
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAccountNumberValid && !_isSubmitting
                  ? Colors.white
                  : Colors.white.withOpacitySafe(0.3),
            ),
            child: Text(
              _isSubmitting ? 'Sending...' : 'Send reset code',
              style: theme.textTheme.labelLarge?.copyWith(
                color: (_isAccountNumberValid && !_isSubmitting)
                    ? primary
                    : Colors.white60,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Verify reset code',
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 4- to 6-digit code sent for account ${_maskedAccountNumber()}.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacitySafe(0.85),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Verification code',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white70,
            ),
            hintText: 'Enter 4- to 6-digit code',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white54,
            ),
            filled: true,
            fillColor: Colors.white.withOpacitySafe(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_isOtpValid && !_isSubmitting)
                ? _handleVerifyOtp
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isOtpValid && !_isSubmitting
                  ? Colors.white
                  : Colors.white.withOpacitySafe(0.3),
            ),
            child: Text(
              _isSubmitting ? 'Verifying...' : 'Verify code',
              style: theme.textTheme.labelLarge?.copyWith(
                color: (_isOtpValid && !_isSubmitting)
                    ? primary
                    : Colors.white60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = _ResetStep.account),
            child: Text(
              'Use a different account number',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(ThemeData theme, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Set new password',
          style: theme.textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a new password for account ${_maskedAccountNumber()}.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacitySafe(0.85),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'New password',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white70,
            ),
            hintText: 'At least 6 characters',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white54,
            ),
            filled: true,
            fillColor: Colors.white.withOpacitySafe(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          'Confirm password',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white70,
            ),
            hintText: 'Re-enter the same password',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white54,
            ),
            filled: true,
            fillColor: Colors.white.withOpacitySafe(0.15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacitySafe(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_isPasswordValid && !_isSubmitting)
                ? _handlePasswordReset
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPasswordValid && !_isSubmitting
                  ? Colors.white
                  : Colors.white.withOpacitySafe(0.3),
            ),
            child: Text(
              _isSubmitting ? 'Resetting...' : 'Reset password',
              style: theme.textTheme.labelLarge?.copyWith(
                color: (_isPasswordValid && !_isSubmitting)
                    ? primary
                    : Colors.white60,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    final currentContent = switch (_step) {
      _ResetStep.account => _buildAccountStep(theme, primary),
      _ResetStep.otp => _buildOtpStep(theme, primary),
      _ResetStep.password => _buildPasswordStep(theme, primary),
    };

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
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      tooltip: 'Back to sign in',
                    ),
                    currentContent,
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'Back to sign in',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
