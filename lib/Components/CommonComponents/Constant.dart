import 'package:flutter/material.dart';

class AppConstants {
  // Breakpoints for different devices
  static const double mobileBreakpoint = 480.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  static const double largeDesktopBreakpoint = 1440.0;

  // Sidebar widths
  static const double sidebarExpandedWidth = 280.0;
  static const double sidebarCollapsedWidth = 75.0;
  static const double sidebarTabletWidth = 240.0;

  // Responsive padding
  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return desktopPadding;
    if (width >= tabletBreakpoint) return tabletPadding;
    return mobilePadding;
  }

  // Spacing
  static const double desktopPadding = 24.0;
  static const double tabletPadding = 20.0;
  static const double mobilePadding = 16.0;
  static const double largeSpacing = 48.0;
  static const double mediumSpacing = 24.0;
  static const double smallSpacing = 16.0;
  static const double tinySpacing = 8.0;

  // Content margins
  static double getContentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return 32.0;
    if (width >= desktopBreakpoint) return 24.0;
    if (width >= tabletBreakpoint) return 20.0;
    return 16.0;
  }

  // Top bar height
  static double getTopBarHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 80.0;
    if (width >= tabletBreakpoint) return 70.0;
    return 60.0;
  }

  // Device type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  // Text Styles - Responsive
  static TextStyle getHeaderTextStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );
    } else if (width >= tabletBreakpoint) {
      return const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );
    } else {
      return const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      );
    }
  }

  static TextStyle getSubheaderTextStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return const TextStyle(
        fontSize: 20,
        color: Colors.black54,
      );
    } else if (width >= tabletBreakpoint) {
      return const TextStyle(
        fontSize: 18,
        color: Colors.black54,
      );
    } else {
      return const TextStyle(
        fontSize: 16,
        color: Colors.black54,
      );
    }
  }

  // Grid columns for responsive layout
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= largeDesktopBreakpoint) return 4;
    if (width >= desktopBreakpoint) return 3;
    if (width >= tabletBreakpoint) return 2;
    return 1;
  }

  // Card dimensions
  static double getCardHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 200.0;
    if (width >= tabletBreakpoint) return 180.0;
    return 160.0;
  }

  // Border radius
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}