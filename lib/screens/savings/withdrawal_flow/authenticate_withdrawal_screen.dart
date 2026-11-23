import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_scaffold.dart';
import '../../../core/color_ext.dart';
import 'withdrawal_model.dart';

class AuthenticateWithdrawalScreen extends StatefulWidget {
  final WithdrawalData data;

  const AuthenticateWithdrawalScreen({super.key, required this.data});

  @override
  State<AuthenticateWithdrawalScreen> createState() =>
      _AuthenticateWithdrawalScreenState();
}

class _AuthenticateWithdrawalScreenState
    extends State<AuthenticateWithdrawalScreen> {
  String _pinCode = '';
  String? _errorMessage;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
  }

  void _appendDigit(String digit) {
    if (_isValidating) return;
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
    if (!_isValidating && _pinCode.isNotEmpty) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _validateAndProceed() async {
    if (!mounted || _isValidating) return;
    if (_pinCode.length != 4) {
      setState(() => _errorMessage = 'PIN must be 4 digits');
      return;
    }

    setState(() => _isValidating = true);
    context.push(
      '/withdrawal/processing',
      extra: widget.data.copyWith(pin: _pinCode),
    );
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
            const SizedBox(height: 12),
            // Lock Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacitySafe(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 30,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
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
              'Enter the 4-digit transaction PIN you created during signup.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacitySafe(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // PIN Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    width: 42,
                    height: 42,
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
                              width: 10,
                              height: 10,
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
            const SizedBox(height: 20),
            // Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map(
                    (digit) => _KeypadButton(
                      label: digit.toString(),
                      onPressed: () => _appendDigit(digit.toString()),
                    ),
                  ),
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
            const SizedBox(height: 20),
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
                        color: theme.colorScheme.onSurface.withOpacitySafe(
                          0.65,
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
            color: theme.colorScheme.surfaceContainerHighest.withOpacitySafe(
              0.35,
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDelete
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
