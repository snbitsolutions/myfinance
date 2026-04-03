import 'dart:ui';
import 'package:flutter/material.dart';
import 'color_ext.dart';

class AppCard extends StatelessWidget {
  static const _radius = 24.0;
  static const _defaultPadding = EdgeInsets.all(16);
  static const _defaultMargin = EdgeInsets.only(bottom: 16);
  static const _defaultBlurSigma = 12.0;

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double blurSigma;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin = _defaultMargin,
    this.backgroundColor,
    this.onTap,
    this.blurSigma = _defaultBlurSigma,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(_radius);
    final cardDecoration = BoxDecoration(
      color: (backgroundColor ?? theme.colorScheme.surface).withValues(
        alpha: 0.4,
      ),
      borderRadius: borderRadius,
      border: Border.all(
        color: theme.colorScheme.onSurface.withOpacitySafe(0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.onSurface.withOpacitySafe(0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );

    Widget cardContent = Ink(
      padding: padding ?? _defaultPadding,
      decoration: cardDecoration,
      child: child,
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: cardContent,
        ),
      ),
    );
  }
}
