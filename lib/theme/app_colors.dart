import 'package:flutter/material.dart';

/// Light pink theme colors. Use these for consistent branding and cards.
class AppColors {
  AppColors._();

  /// Primary brand color (light pink / rose).
  static const Color primary = Color(0xFFE11D8C);

  /// Darker variant for gradients and contrast.
  static const Color primaryDark = Color(0xFFBE185D);

  /// Lighter variant for gradients and highlights.
  static const Color primaryLight = Color(0xFFF472B6);

  /// Very light tint for backgrounds (e.g. "You" highlights).
  static const Color primaryLightBg = Color(0xFFFCE7F3);

  /// Dark text that matches the theme.
  static const Color textPrimary = Color(0xFF831843);

  /// Secondary text.
  static const Color textSecondary = Color(0xFF6B5C6B);

  // --- Light pink theme surfaces & cards ---

  /// Main scaffold / screen background.
  static const Color surface = Color(0xFFFDF2F8);

  /// Card background (elevated white).
  static const Color card = Color(0xFFFFFFFF);

  /// Slightly tinted card (e.g. secondary panels).
  static const Color cardTint = Color(0xFFFDF2F8);

  /// Border for cards and dividers.
  static const Color border = Color(0xFFFBCFE8);

  /// Balance / hero card gradient start (top-left).
  static const Color balanceStart = Color(0xFFF472B6);

  /// Balance / hero card gradient end (bottom-right).
  static const Color balanceEnd = Color(0xFFBE185D);

  /// Chart line and accent (pink).
  static const Color chartAccent = Color(0xFFE11D8C);

  /// Success / live indicator (pink).
  static const Color success = Color(0xFFBE185D);

  /// App bar background (matches surface).
  static const Color appBar = Color(0xFFFDF2F8);
}
