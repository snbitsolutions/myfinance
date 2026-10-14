import 'package:flutter/material.dart';

class BalanceCardShell extends StatelessWidget {
  final List<Color> gradientColors;
  final Color shadowColor;
  final EdgeInsets contentPadding;
  final Widget child;

  const BalanceCardShell({
    super.key,
    required this.gradientColors,
    required this.shadowColor,
    required this.contentPadding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -42,
              right: -34,
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -56,
              left: -38,
              child: Container(
                width: 146,
                height: 146,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: const AdepaLogoBadge(size: 104),
            ),
            Padding(padding: contentPadding, child: child),
          ],
        ),
      ),
    );
  }
}

class AdepaLogoBadge extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const AdepaLogoBadge({
    super.key,
    this.size = 104,
    this.color = Colors.white,
    this.opacity = 0.28,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: Image.asset(
            'images/adepa_teachers_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class TreeLogoBadge extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const TreeLogoBadge({
    super.key,
    this.size = 132,
    this.color = Colors.white,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: Transform.scale(
            scale: 1.45,
            alignment: Alignment.topCenter,
            child: Image.asset(
              'images/adepa_teachers_logo.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }
}
