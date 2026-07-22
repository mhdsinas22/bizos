import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double maxContentWidth = 1200;
  static const double maxFormWidth = 600;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width <= tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletMax;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static int getGridColumnCount(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return mobile;
    if (width <= tabletMax) return tablet;
    return desktop;
  }
}
