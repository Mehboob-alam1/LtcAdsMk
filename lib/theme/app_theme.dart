import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App theme: layout and decoration constants.
class AppTheme {
  AppTheme._();

  /// Card corner radius (rounded style).
  static const double cardRadius = 20.0;

  /// Smaller radius for chips and inner elements.
  static const double chipRadius = 12.0;

  /// Standard horizontal screen padding.
  static const double screenPaddingH = 20.0;

  /// Standard vertical screen padding.
  static const double screenPaddingV = 20.0;

  /// Space between major sections.
  static const double sectionSpacing = 20.0;

  /// Space between cards.
  static const double cardSpacing = 16.0;

  /// Standard card padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  /// Card shadow (subtle).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Hero/balance card shadow.
  static List<BoxShadow> get balanceCardShadow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.2),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Standard elevated card decoration (white, rounded, shadow).
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: cardShadow,
      );

  /// Hero card (gradient) decoration.
  static BoxDecoration balanceCardDecoration() => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.balanceStart, AppColors.balanceEnd],
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: balanceCardShadow,
      );
}
