import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _logoLoopController;
  late Animation<double> _logoScale;
  late Animation<double> _contentFade;
  late Animation<double> _logoIntroPulse;
  late Animation<double> _logoLoopScale;
  late Animation<double> _logoFloatY;
  late Animation<double> _logoTilt;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _logoIntroPulse = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
      ),
    );
    _logoLoopScale = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(parent: _logoLoopController, curve: Curves.easeInOut),
    );
    _logoFloatY = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _logoLoopController, curve: Curves.easeInOut),
    );
    _logoTilt = Tween<double>(begin: -0.018, end: 0.018).animate(
      CurvedAnimation(parent: _logoLoopController, curve: Curves.easeInOut),
    );

    _animationController.forward().whenComplete(() {
      if (!mounted) return;
      _logoLoopController.repeat(reverse: true);
    });
    _navigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoLoopController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding =
          prefs.getBool(AppConstants.sharedPrefKeyOnboarding) ?? false;
      if (!mounted) return;

      if (seenOnboarding) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    } catch (_) {
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _animationController,
                    _logoLoopController,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale:
                          _logoScale.value *
                          _logoIntroPulse.value *
                          (_logoLoopController.isAnimating
                              ? _logoLoopScale.value
                              : 1.0),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          _logoLoopController.isAnimating
                              ? _logoFloatY.value
                              : 0,
                        ),
                        child: Transform.rotate(
                          angle: _logoLoopController.isAnimating
                              ? _logoTilt.value
                              : 0,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: Image.asset(
                      'images/adepa_teachers_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      Text(
                        'Smart Finance, Smart Future',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacitySafe(
                            0.38,
                          ),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Getting things ready…',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacitySafe(0.55),
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
