import 'package:flutter/material.dart';

/// Responsive utility class for handling different device sizes
/// Breakpoints:
/// - Small phone: < 400px
/// - Normal phone: 400px - 600px
/// - Large phone: 600px - 800px
/// - Tablet: >= 800px
class ResponsiveUtils {
  static const double SMALL_PHONE_BREAKPOINT = 400;
  static const double NORMAL_PHONE_BREAKPOINT = 600;
  static const double LARGE_PHONE_BREAKPOINT = 800;
  static const double TABLET_BREAKPOINT = 1200;

  /// Determines the current device type based on screen width
  static DeviceType getDeviceType(double width) {
    if (width < SMALL_PHONE_BREAKPOINT) {
      return DeviceType.smallPhone;
    } else if (width < NORMAL_PHONE_BREAKPOINT) {
      return DeviceType.normalPhone;
    } else if (width < LARGE_PHONE_BREAKPOINT) {
      return DeviceType.largePhone;
    } else if (width < TABLET_BREAKPOINT) {
      return DeviceType.tablet;
    } else {
      return DeviceType.largTablet;
    }
  }

  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(
    double baseSize,
    double screenWidth, {
    double? minSize,
    double? maxSize,
  }) {
    final scaleFactor = screenWidth / 375.0; // Base on iPhone 8 width
    final responsiveSize = baseSize * scaleFactor;

    if (minSize != null && responsiveSize < minSize) {
      return minSize;
    }
    if (maxSize != null && responsiveSize > maxSize) {
      return maxSize;
    }
    return responsiveSize;
  }

  /// Get responsive padding/margin based on screen width
  static double getResponsiveValue(
    double baseValue,
    double screenWidth, {
    double? minValue,
    double? maxValue,
  }) {
    final scaleFactor = screenWidth / 375.0;
    final responsiveValue = baseValue * scaleFactor;

    if (minValue != null && responsiveValue < minValue) {
      return minValue;
    }
    if (maxValue != null && responsiveValue > maxValue) {
      return maxValue;
    }
    return responsiveValue;
  }

  /// Get responsive container width for cards/items
  static double getResponsiveContainerWidth(double screenWidth) {
    final deviceType = getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.smallPhone:
        return screenWidth * 0.9;
      case DeviceType.normalPhone:
        return screenWidth * 0.85;
      case DeviceType.largePhone:
        return screenWidth * 0.8;
      case DeviceType.tablet:
        return 400;
      case DeviceType.largTablet:
        return 600;
    }
  }

  /// Get responsive grid spacing
  static double getResponsiveGridSpacing(double screenWidth) {
    final deviceType = getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 8;
      case DeviceType.normalPhone:
        return 12;
      case DeviceType.largePhone:
        return 16;
      case DeviceType.tablet:
        return 20;
      case DeviceType.largTablet:
        return 24;
    }
  }

  /// Get number of columns for grid based on screen width
  static int getGridColumns(double screenWidth) {
    final deviceType = getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 2;
      case DeviceType.normalPhone:
        return 2;
      case DeviceType.largePhone:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.largTablet:
        return 4;
    }
  }

  /// Get responsive button height
  static double getResponsiveButtonHeight(double screenHeight) {
    if (screenHeight < 600) {
      return screenHeight * 0.06;
    } else if (screenHeight < 800) {
      return screenHeight * 0.065;
    } else {
      return screenHeight * 0.07;
    }
  }

  /// Get responsive image size for logos/avatars
  static double getResponsiveImageSize(
    double baseSize,
    double screenWidth, {
    double? minSize,
    double? maxSize,
  }) {
    final scaleFactor = screenWidth / 375.0;
    final responsiveSize = baseSize * scaleFactor;

    if (minSize != null && responsiveSize < minSize) {
      return minSize;
    }
    if (maxSize != null && responsiveSize > maxSize) {
      return maxSize;
    }
    return responsiveSize;
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(double baseRadius, double screenWidth) {
    final scaleFactor = screenWidth / 375.0;
    return baseRadius * scaleFactor;
  }

  /// Get responsive horizontal padding
  static double getResponsiveHorizontalPadding(double screenWidth) {
    final deviceType = getDeviceType(screenWidth);
    switch (deviceType) {
      case DeviceType.smallPhone:
        return screenWidth * 0.05;
      case DeviceType.normalPhone:
        return screenWidth * 0.06;
      case DeviceType.largePhone:
        return screenWidth * 0.07;
      case DeviceType.tablet:
        return screenWidth * 0.1;
      case DeviceType.largTablet:
        return screenWidth * 0.15;
    }
  }

  /// Check if device is in portrait or landscape
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is tablet or larger
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= LARGE_PHONE_BREAKPOINT;
  }

  /// Check if device is large tablet
  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= TABLET_BREAKPOINT;
  }

  /// Get maximum content width for tablets/desktops
  static double getMaxContentWidth(double screenWidth) {
    if (screenWidth >= TABLET_BREAKPOINT) {
      return 1200;
    } else if (screenWidth >= LARGE_PHONE_BREAKPOINT) {
      return 900;
    } else {
      return screenWidth;
    }
  }
}

/// Device type enum for easier type checking
enum DeviceType {
  smallPhone,    // < 400px
  normalPhone,   // 400px - 600px
  largePhone,    // 600px - 800px
  tablet,        // 800px - 1200px
  largTablet,    // >= 1200px
}
