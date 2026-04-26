import 'package:flutter/widgets.dart';

class Responsive {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1100;
  static const double large = 1400;

  static bool isCompact(BuildContext context) => width(context) < compact;

  static bool isMedium(BuildContext context) =>
      width(context) >= compact && width(context) < medium;

  static bool isExpanded(BuildContext context) => width(context) >= medium;

  static bool isLarge(BuildContext context) => width(context) >= large;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double maxContentWidth(BuildContext context) {
    final w = width(context);
    if (w >= large) return 1200;
    if (w >= expanded) return 1000;
    if (w >= medium) return 920;
    if (w >= compact) return 680;
    return w;
  }

  static double horizontalGutter(BuildContext context) {
    final w = width(context);
    if (w >= large) return 40;
    if (w >= expanded) return 28;
    if (w >= medium) return 20;
    if (w >= compact) return 20;
    return 0;
  }
}
