import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import '../../../core/services/secure_auth_storage.dart';
import 'withdrawal_model.dart';

class AuthenticateWithdrawalScreen extends StatefulWidget {
  final WithdrawalData data;

  const AuthenticateWithdrawalScreen({super.key, required this.data});

  @override
  State<AuthenticateWithdrawalScreen> createState() => _AuthenticateWithdrawalScreenState();
}

class _AuthenticateWithdrawalScreenState extends State<AuthenticateWithdrawalScreen> {
  String _pinCode = '';
  String? _errorMessage;

  void _appendDigit(String digit) {
    if (_pinCode.length < 4) {
      setState(() {
        _pinCode += digit;
        _errorMessage = null;
      });
      
      // Auto-submit when 4 digits are entered
      if (_pinCode.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), _validateAndProceed);
      }
    }
  }

  void _deleteDigit() {
    if (_pinCode.isNotEmpty) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _validateAndProceed() async {
    if (_pinCode.length != 4) {
      setState(() => _errorMessage = 'PIN must be 4 digits');
      return;
    }

    try {
      // Get stored PIN from secure storage
      final storedPin = await SecureAuthStorage.instance.readPin();

      if (storedPin == _pinCode) {
        // PIN is correct, proceed to processing
        if (!mounted) return;
        context.push('/withdrawal/processing', extra: widget.data);
      } else {
        // PIN is incorrect
        setState(() {
          _errorMessage = 'Invalid PIN. Please try again.';
          _pinCode = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating PIN. Please try again.';
        _pinCode = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Authenticate',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Lock Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacitySafe(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Enter your PIN',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Please enter your 4-digit PIN to authorize this withdrawal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // PIN Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: i < _pinCode.length
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: i < _pinCode.length
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Error Message
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            // Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((num) => _KeypadButton(
                        label: num.toString(),
                        onPressed: () => _appendDigit(num.toString()),
                      )),
                  _KeypadButton(
                    label: '0',
                    onPressed: () => _appendDigit('0'),
                  ),
                  _KeypadButton(
                    label: '⌫',
                    onPressed: _deleteDigit,
                    isDelete: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Forgot PIN Link
            TextButton(
              onPressed: () {
                // TODO: Implement forgot PIN flow
              },
              child: Text(
                'Forgot PIN?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Do not share the app or go back while we are processing.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacitySafe(0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDelete;

  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDelete ? theme.colorScheme.error : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

