import 'package:flutter/material.dart';

/// ETH theme colors. Use these for consistent branding and cards.
class AppColors {
  AppColors._();

  /// Primary brand color (#497493).
  static const Color primary = Color(0xFF497493);

  /// Darker variant for gradients and contrast.
  static const Color primaryDark = Color(0xFF3A5C73);

  /// Lighter variant for gradients and highlights.
  static const Color primaryLight = Color(0xFF6B8FA8);

  /// Very light tint for backgrounds (e.g. "You" highlights).
  static const Color primaryLightBg = Color(0xFFE8EEF2);

  /// Dark text that matches the theme.
  static const Color textPrimary = Color(0xFF1E3647);

  /// Secondary text.
  static const Color textSecondary = Color(0xFF5C6B7A);

  // --- ETH theme surfaces & cards ---

  /// Main scaffold / screen background.
  static const Color surface = Color(0xFFF2F6F9);

  /// Card background (elevated white).
  static const Color card = Color(0xFFFFFFFF);

  /// Slightly tinted card (e.g. secondary panels).
  static const Color cardTint = Color(0xFFF8FAFC);

  /// Border for cards and dividers.
  static const Color border = Color(0xFFE2E8ED);

  /// Balance / hero card gradient start (top-left).
  static const Color balanceStart = Color(0xFF497493);

  /// Balance / hero card gradient end (bottom-right).
  static const Color balanceEnd = Color(0xFF2E4A5C);

  /// Chart line and accent (ETH blue).
  static const Color chartAccent = Color(0xFF497493);

  /// Success / live indicator (soft teal).
  static const Color success = Color(0xFF2E7D6E);

  /// App bar background (matches surface).
  static const Color appBar = Color(0xFFF2F6F9);
}
