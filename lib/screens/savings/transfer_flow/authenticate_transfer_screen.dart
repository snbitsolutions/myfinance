import 'package:flutter/material.dart';
import '../../../core/app_card.dart';
import '../../../core/app_scaffold.dart';

class AuthenticateTransferScreen extends StatefulWidget {
  const AuthenticateTransferScreen({super.key});

  @override
  State<AuthenticateTransferScreen> createState() =>
      _AuthenticateTransferScreenState();
}

class _AuthenticateTransferScreenState
    extends State<AuthenticateTransferScreen> {
  late String _pinInput;
  late String _errorMessage;

  @override
  void initState() {
    super.initState();
    _pinInput = '';
    _errorMessage = '';
  }

  void _addDigit(String digit) {
    if (_pinInput.length < 4) {
      setState(() {
        _pinInput += digit;
        _errorMessage = '';
      });

      if (_pinInput.length == 4) {
        _validateAndProceed();
      }
    }
  }

  void _removeDigit() {
    if (_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _clearPin() {
    setState(() {
      _pinInput = '';
      _errorMessage = '';
    });
  }

  Future<void> _validateAndProceed() async {
    setState(() {
      _errorMessage =
          'Transfer authorization is unavailable because this transfer cannot be submitted to the backend.';
      _pinInput = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Authenticate Transfer',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Text(
              'Enter your PIN to authorize this transfer',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // PIN display
            Center(
              child: AppCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    4,
                    (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < _pinInput.length
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage.isNotEmpty)
              Center(
                child: Text(
                  _errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),

            // Numeric keypad
            _buildKeypad(theme),
            const SizedBox(height: 24),

            // Clear button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearPin,
                icon: const Icon(Icons.refresh),
                label: const Text('Clear PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    const keypadLayout = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['0', 'clear', 'back'],
    ];

    return Column(
      children: keypadLayout.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: key == 'clear'
                      ? _KeypadButton(
                          label: 'C',
                          onPressed: _clearPin,
                        )
                      : key == 'back'
                          ? _KeypadButton(
                              label: '⌫',
                              onPressed: _removeDigit,
                            )
                          : _KeypadButton(
                              label: key,
                              onPressed: () => _addDigit(key),
                            ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _KeypadButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _isPressed
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPressed
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
