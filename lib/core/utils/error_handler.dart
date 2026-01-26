import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import 'logger.dart';

/// Error handling utility for UI layer
class ErrorHandler {
  /// Get user-friendly error message from exception
  static String getErrorMessage(dynamic exception) {
    AppLogger.error('Error occurred', exception);

    if (exception is ValidationException) {
      return exception.message;
    }

    if (exception is AuthException) {
      return exception.message;
    }

    if (exception is NetworkException) {
      return AppConstants.networkErrorMessage;
    }

    if (exception is TimeoutException) {
      return AppConstants.timeoutErrorMessage;
    }

    if (exception is ServerException) {
      return exception.message;
    }

    if (exception is NotFoundException) {
      return exception.message;
    }

    if (exception is AppException) {
      return exception.message;
    }

    return AppConstants.genericErrorMessage;
  }

  /// Show error snackbar in ScaffoldMessenger context
  static void showErrorSnackBar(
    BuildContext context,
    dynamic exception, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = getErrorMessage(exception);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error dialog
  static void showErrorDialog(
    BuildContext context,
    dynamic exception, {
    VoidCallback? onRetry,
  }) {
    final message = getErrorMessage(exception);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must not exceed ${AppConstants.maxPasswordLength} characters';
    }

    return null;
  }

  /// Validate PIN
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    if (value.length != AppConstants.pinLength) {
      return 'PIN must be ${AppConstants.pinLength} digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }

    return null;
  }

  /// Validate OTP
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }

    if (value.length != AppConstants.otpLength) {
      return 'Verification code must be ${AppConstants.otpLength} digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Verification code must contain only numbers';
    }

    return null;
  }

  /// Validate amount
  static String? validateAmount(
    String? value, {
    double? minAmount,
    double? maxAmount,
  }) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (minAmount != null && amount < minAmount) {
      return 'Amount must be at least ${AppConstants.currencySymbol}$minAmount';
    }

    if (maxAmount != null && amount > maxAmount) {
      return 'Amount must not exceed ${AppConstants.currencySymbol}$maxAmount';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
