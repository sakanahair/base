import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A responsive helper utility class that provides breakpoints and responsive design utilities
class ResponsiveHelper {
  // Breakpoint constants
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1200.0;

  // Minimum touch target size for accessibility
  static const double minTouchTarget = 48.0;

  /// Check if the current screen is mobile (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if the current screen is tablet (600px - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if the current screen is desktop (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if the current screen is large desktop (>= 1200px)
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// Get responsive horizontal padding based on screen size
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
  }

  /// Get responsive grid column count
  static int getGridColumnCount(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 4,
  }) {
    if (isDesktop(context)) {
      return desktopColumns;
    } else if (isTablet(context)) {
      return tabletColumns;
    } else {
      return mobileColumns;
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double mobileScale = 0.9,
    double tabletScale = 1.0,
    double desktopScale = 1.0,
  }) {
    if (isMobile(context)) {
      return baseFontSize * mobileScale;
    } else if (isTablet(context)) {
      return baseFontSize * tabletScale;
    } else {
      return baseFontSize * desktopScale;
    }
  }

  /// Get appropriate icon size for the current screen size
  static double getResponsiveIconSize(BuildContext context) {
    if (isMobile(context)) {
      return 20.0;
    } else if (isTablet(context)) {
      return 22.0;
    } else {
      return 24.0;
    }
  }

  /// Get appropriate button height for the current screen size
  static double getResponsiveButtonHeight(BuildContext context) {
    if (isMobile(context)) {
      return minTouchTarget;
    } else {
      return 40.0;
    }
  }

  /// Add haptic feedback for mobile interactions
  static void addHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Add stronger haptic feedback for important actions
  static void addHapticFeedbackMedium() {
    HapticFeedback.mediumImpact();
  }

  /// Get appropriate app bar height for the current screen size
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return 56.0; // Standard mobile app bar height
    } else {
      return 64.0; // Desktop app bar height
    }
  }

  /// Check if device supports touch (mobile/tablet)
  static bool isTouchDevice(BuildContext context) {
    return isMobile(context) || isTablet(context);
  }

  /// Get responsive card border radius
  static double getCardBorderRadius(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else {
      return 8.0;
    }
  }

  /// Get responsive dialog constraints
  static BoxConstraints getDialogConstraints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      );
    } else if (isTablet(context)) {
      return const BoxConstraints(
        maxWidth: 500,
        maxHeight: 600,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 600,
        maxHeight: 700,
      );
    }
  }

  /// Get responsive spacing for layouts
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  /// Get responsive margin for components
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(8.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  /// Get responsive cross axis count for grids
  static int getResponsiveCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else if (isLargeDesktop(context)) {
      return 4;
    } else {
      return 3;
    }
  }

  /// Get responsive aspect ratio for cards
  static double getCardAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 2.5; // Wider cards on mobile
    } else if (isTablet(context)) {
      return 1.8;
    } else {
      return 1.5;
    }
  }

  /// Get responsive drawer width
  static double getDrawerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * 0.85; // 85% of screen width on mobile
    } else {
      return 280.0; // Fixed width on larger screens
    }
  }

  /// Get responsive table column widths
  static Map<int, TableColumnWidth> getResponsiveColumnWidths(BuildContext context, int columnCount) {
    if (isMobile(context)) {
      // On mobile, make columns more flexible
      return {
        for (int i = 0; i < columnCount; i++)
          i: const FlexColumnWidth(),
      };
    } else {
      // On larger screens, use mixed width strategy
      return {
        0: const FlexColumnWidth(2), // First column (names) gets more space
        for (int i = 1; i < columnCount - 1; i++)
          i: const FlexColumnWidth(1),
        columnCount - 1: const FixedColumnWidth(100), // Actions column fixed width
      };
    }
  }

  /// Show responsive snackbar
  static void showResponsiveSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: isMobile(context) 
          ? SnackBarBehavior.floating 
          : SnackBarBehavior.fixed,
      margin: isMobile(context) 
          ? const EdgeInsets.all(16) 
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Extension on BuildContext to make responsive helper methods easily accessible
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  bool get isTouchDevice => ResponsiveHelper.isTouchDevice(this);
  
  EdgeInsets get responsivePadding => ResponsiveHelper.getResponsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding => ResponsiveHelper.getResponsiveHorizontalPadding(this);
  double get responsiveSpacing => ResponsiveHelper.getResponsiveSpacing(this);
  EdgeInsets get responsiveMargin => ResponsiveHelper.getResponsiveMargin(this);
  double get responsiveButtonHeight => ResponsiveHelper.getResponsiveButtonHeight(this);
  double get responsiveIconSize => ResponsiveHelper.getResponsiveIconSize(this);
}