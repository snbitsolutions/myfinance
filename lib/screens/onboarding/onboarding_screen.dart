import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_scaffold.dart';
import '../../core/color_ext.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  double _pageOffset = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    if (!_pageCtrl.hasClients || !mounted) return;
    final nextOffset = _pageCtrl.page ?? _page.toDouble();
    if ((nextOffset - _pageOffset).abs() < 0.0001) return;
    setState(() => _pageOffset = nextOffset);
  }

  List<OnboardingPageData> _pages(ThemeData theme) => [
    OnboardingPageData(
      title: 'Welcome to ${AppConstants.appName}',
      subtitle: 'Fast loans and smart savings in one app',
      image: 'images/adepa_teachers_logo.png',
      color: theme.colorScheme.primary,
    ),
    OnboardingPageData(
      title: 'Quick Loans',
      subtitle:
          'Apply and receive funds instantly with flexible repayment plans',
      icon: Icons.flash_on,
      color: theme.colorScheme.secondary,
    ),
    OnboardingPageData(
      title: 'Smart Savings',
      subtitle: 'Set goals, track progress, and watch your money grow',
      icon: Icons.savings,
      color: theme.colorScheme.primary,
    ),
    OnboardingPageData(
      title: 'Easy Payments',
      subtitle:
          'Secure payments with multiple options and instant confirmation',
      icon: Icons.payment,
      color: theme.colorScheme.secondary,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.sharedPrefKeyOnboarding, true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _pageCtrl.removeListener(_handlePageScroll);
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = _pages(theme);
    final isCompact = MediaQuery.sizeOf(context).height < 760;

    return AppScaffold(
      title: '',
      showBack: false,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: pages.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (_, i) => OnboardingPage(
                  pages[i],
                  isActive: _page == i,
                  isCompact: isCompact,
                  pageOffset: _pageOffset,
                  pageIndex: i,
                ),
              ),
            ),
            _controls(theme, pages, isCompact: isCompact),
          ],
        ),
      ),
    );
  }

  Widget _controls(
    ThemeData theme,
    List<OnboardingPageData> pages, {
    required bool isCompact,
  }) {
    final isLast = _page == pages.length - 1;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (i) => GestureDetector(
                onTap: () => _pageCtrl.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 4),
                  width: _page == i ? (isCompact ? 24 : 28) : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacitySafe(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 20 : 32),
          Row(
            children: [
              if (_page > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pageCtrl.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, isCompact ? 48 : 52),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_page > 0) const SizedBox(width: 12),
              Expanded(
                flex: _page > 0 ? 2 : 1,
                child: ElevatedButton(
                  onPressed: isLast
                      ? _finish
                      : () => _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: Size(double.infinity, isCompact ? 48 : 52),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Row(
                      key: ValueKey<bool>(isLast),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isLast ? 'Get Started' : 'Next'),
                        if (isLast) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_outline, size: 20),
                        ] else ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 20 : 32),
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
    required this.isActive,
    required this.isCompact,
    required this.pageOffset,
    required this.pageIndex,
  });

  final OnboardingPageData data;
  final bool isActive;
  final bool isCompact;
  final double pageOffset;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final pageColor = data.color;
    final pageDelta = (pageOffset - pageIndex).clamp(-1.2, 1.2).toDouble();
    final distance = pageDelta.abs().clamp(0.0, 1.0);
    final intensity = disableAnimations ? 0.0 : (isCompact ? 0.55 : 0.8);
    final depthScale = 1 - (distance * 0.035 * intensity);
    final depthOpacity = 1 - (distance * 0.12 * intensity);
    final backgroundShift = pageDelta * (disableAnimations ? 0 : 18);
    final contentShift = pageDelta * (disableAnimations ? 0 : -8);
    final iconShift = pageDelta * (disableAnimations ? 0 : -5);
    final titleStyle =
        (isCompact
                ? theme.textTheme.titleLarge
                : theme.textTheme.headlineMedium)
            ?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            );
    final subtitleStyle =
        (isCompact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)
            ?.copyWith(
              color: theme.colorScheme.onSurface.withOpacitySafe(0.7),
              height: 1.5,
            );

    return ClipRect(
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(backgroundShift, 0),
            child: Container(
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
            ),
          ),
          Transform.translate(
            offset: Offset(contentShift, 0),
            child: Opacity(
              opacity: depthOpacity,
              child: Transform.scale(
                scale: depthScale,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: isActive ? 1 : 0.92,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: isActive ? 1 : 0.75,
                          duration: const Duration(milliseconds: 280),
                          child: Transform.translate(
                            offset: Offset(iconShift, 0),
                            child: _buildIcon(pageColor),
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 28 : 56),
                      AnimatedSlide(
                        offset: isActive ? Offset.zero : const Offset(0, 0.04),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        child: AnimatedOpacity(
                          opacity: isActive ? 1 : 0.8,
                          duration: const Duration(milliseconds: 240),
                          child: Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: titleStyle,
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 12 : 16),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 8 : 16,
                        ),
                        child: AnimatedSlide(
                          offset: isActive
                              ? Offset.zero
                              : const Offset(0, 0.06),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          child: AnimatedOpacity(
                            opacity: isActive ? 1 : 0.78,
                            duration: const Duration(milliseconds: 260),
                            child: Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: subtitleStyle,
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
        ],
      ),
    );
  }

  Widget _buildIcon(Color pageColor) {
    final imageSize = isCompact ? 128.0 : 160.0;
    final iconSize = isCompact ? 54.0 : 70.0;

    if (data.image != null) {
      return SizedBox(
        width: imageSize,
        height: imageSize,
        child: Image.asset(data.image!, fit: BoxFit.contain),
      );
    }

    return Icon(data.icon, size: iconSize, color: pageColor);
  }
}
