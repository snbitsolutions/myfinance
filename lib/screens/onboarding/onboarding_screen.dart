import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _onboardingBackgroundImage = 'images/onboarding_city.jpg';
  late final _page = OnboardingPageData(
    title: 'Welcome to ${AppConstants.appName}',
    subtitle: 'Fast loans and smart savings in one app',
    image: _onboardingBackgroundImage,
    color: Colors.white,
  );

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).height < 760;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          OnboardingPage(
            _page,
            isCompact: isCompact,
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 24,
                    0,
                    isCompact ? 16 : 24,
                    isCompact ? 20 : 32,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _finish,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Get Started'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        minimumSize: Size(double.infinity, isCompact ? 48 : 52),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    this.icon,
    this.image,
    required this.color,
  });
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? image;
  final Color color;
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage(
    this.data, {
    super.key,
    required this.isCompact,
  });

  final OnboardingPageData data;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final pageColor = data.color;
    final titleColor = data.image != null
        ? Colors.white
        : theme.colorScheme.onSurface;
    final subtitleColor = data.image != null
        ? Colors.white.withOpacitySafe(0.9)
        : theme.colorScheme.onSurface.withOpacitySafe(0.7);
    final titleStyle =
        (isCompact
                ? theme.textTheme.titleLarge
                : theme.textTheme.headlineMedium)
            ?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
              shadows: data.image == null
                  ? null
                  : const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
            );
    final subtitleStyle =
        (isCompact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)
            ?.copyWith(
              color: subtitleColor,
              height: 1.5,
              shadows: data.image == null
                  ? null
                  : const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 10,
                        offset: Offset(0, 1),
                      ),
                    ],
            );

    return ClipRect(
      child: Stack(
        children: [
          data.image == null
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        pageColor.withOpacitySafe(0.05),
                        pageColor.withOpacitySafe(0.1),
                      ],
                    ),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _AnimatedOnboardingBackground(
                      image: Image.asset(
                        data.image!,
                        key: const ValueKey('onboarding-background-0'),
                        fit: BoxFit.cover,
                      ),
                      isActive: true,
                      disableAnimations: disableAnimations,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x26000000),
                            Color(0x33000000),
                            Color(0xB3000000),
                          ],
                          stops: [0, 0.45, 1],
                        ),
                      ),
                    ),
                  ],
                ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data.icon != null) ...[
                  _buildIcon(pageColor),
                  SizedBox(height: isCompact ? 28 : 56),
                ],
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: titleStyle,
                ),
                SizedBox(height: isCompact ? 12 : 16),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 16,
                  ),
                  child: Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: subtitleStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(Color pageColor) {
    final iconSize = isCompact ? 54.0 : 70.0;

    if (data.icon == null) {
      return const SizedBox.shrink();
    }

    return Icon(
      data.icon,
      size: iconSize,
      color: data.image == null ? pageColor : Colors.white,
      shadows: data.image == null
          ? null
          : const [Shadow(color: Color(0x99000000), blurRadius: 12)],
    );
  }
}

class _AnimatedOnboardingBackground extends StatefulWidget {
  const _AnimatedOnboardingBackground({
    required this.image,
    required this.isActive,
    required this.disableAnimations,
  });

  final Widget image;
  final bool isActive;
  final bool disableAnimations;

  @override
  State<_AnimatedOnboardingBackground> createState() =>
      _AnimatedOnboardingBackgroundState();
}

class _AnimatedOnboardingBackgroundState
    extends State<_AnimatedOnboardingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedOnboardingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.disableAnimations != widget.disableAnimations) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isActive && !widget.disableAnimations) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.image,
      builder: (context, image) {
        final controllerValue = _controller.value;
        final progress = widget.disableAnimations || !controllerValue.isFinite
            ? 0.0
            : controllerValue.clamp(0.0, 1.0).toDouble();
        final translation = widget.disableAnimations
            ? 0.0
            : (progress - 0.5) * 12;
        final scale = widget.disableAnimations ? 1.0 : 1.02 + progress * 0.035;
        return Transform.translate(
          offset: Offset(translation.isFinite ? translation : 0, 0),
          child: Transform.scale(
            scale: scale.isFinite ? scale : 1,
            child: image,
          ),
        );
      },
    );
  }
}
