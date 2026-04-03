import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/color_ext.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _showPin = false;

  bool get _canSubmit =>
      _pinController.text.trim().length == 4 &&
      _pinController.text == _confirmController.text;

  bool get _pinMatch => _pinController.text == _confirmController.text;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
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
                      Text(
                        'Create PIN',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a 4-digit PIN to secure your account',
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
                                                _confirmController.text.isEmpty
                                            ? Colors.white.withOpacitySafe(0.2)
                                            : Colors.red.withOpacitySafe(0.5),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            _pinMatch ||
                                                _confirmController.text.isEmpty
                                            ? Colors.white.withOpacitySafe(0.2)
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
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _canSubmit
                                    ? () async {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        await prefs.setString(
                                          'transaction_pin',
                                          _pinController.text.trim(),
                                        );
                                        if (!mounted) return;
                                        context.go('/home');
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _canSubmit
                                      ? Colors.white
                                      : Colors.white.withOpacitySafe(0.3),
                                ),
                                child: Text(
                                  'Create PIN & Continue',
                                  style: theme.textTheme.labelLarge?.copyWith(
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
