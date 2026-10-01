import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // JMD Official Brand Colors (from Logo)
  static const Color primaryNavy = Color(0xFF0C3E7B);
  static const Color primaryDark = Color(0xFF07264F);
  static const Color primaryLight = Color(0xFF1E5BB0);
  static const Color brandRed = Color(0xFFE31E24);
  static const Color brandRedDark = Color(0xFFB81318);

  // Background & Surfaces
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFCBD5E1);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status Badges Colors
  // 1. New
  static const Color statusNewText = Color(0xFF1D4ED8);
  static const Color statusNewBg = Color(0xFFEFF6FF);
  static const Color statusNewBorder = Color(0xFFBFDBFE);

  // 2. Picked Up
  static const Color statusPickedUpText = Color(0xFF6D28D9);
  static const Color statusPickedUpBg = Color(0xFFF5F3FF);
  static const Color statusPickedUpBorder = Color(0xFFDDD6FE);

  // 3. In Transit
  static const Color statusInTransitText = Color(0xFFB45309);
  static const Color statusInTransitBg = Color(0xFFFFFBEB);
  static const Color statusInTransitBorder = Color(0xFFFDE68A);

  // 4. Delivered
  static const Color statusDeliveredText = Color(0xFF15803D);
  static const Color statusDeliveredBg = Color(0xFFF0FDF4);
  static const Color statusDeliveredBorder = Color(0xFFBBF7D0);

  // 5. Failed
  static const Color statusFailedText = Color(0xFFB91C1C);
  static const Color statusFailedBg = Color(0xFFFEF2F2);
  static const Color statusFailedBorder = Color(0xFFFECACA);
}
