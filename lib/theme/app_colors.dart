import 'package:flutter/material.dart';

/// Teal theme colors. Use these for consistent branding and cards.
class AppColors {
  AppColors._();

  /// Primary brand color (teal).
  static const Color primary = Color(0xFF0D9488);

  /// Darker variant for gradients and contrast.
  static const Color primaryDark = Color(0xFF0F766E);

  /// Lighter variant for gradients and highlights.
  static const Color primaryLight = Color(0xFF14B8A6);

  /// Very light tint for backgrounds (e.g. "You" highlights).
  static const Color primaryLightBg = Color(0xFFCCFBF1);

  /// Dark text that matches the theme.
  static const Color textPrimary = Color(0xFF134E4A);

  /// Secondary text.
  static const Color textSecondary = Color(0xFF5C6B7A);

  // --- Teal theme surfaces & cards ---

  /// Main scaffold / screen background.
  static const Color surface = Color(0xFFF0FDFA);

  /// Card background (elevated white).
  static const Color card = Color(0xFFFFFFFF);

  /// Slightly tinted card (e.g. secondary panels).
  static const Color cardTint = Color(0xFFF0FDFA);

  /// Border for cards and dividers.
  static const Color border = Color(0xFF99F6E4);

  /// Balance / hero card gradient start (top-left).
  static const Color balanceStart = Color(0xFF14B8A6);

  /// Balance / hero card gradient end (bottom-right).
  static const Color balanceEnd = Color(0xFF0F766E);

  /// Chart line and accent (teal).
  static const Color chartAccent = Color(0xFF0D9488);

  /// Success / live indicator (teal).
  static const Color success = Color(0xFF0D9488);

  /// App bar background (matches surface).
  static const Color appBar = Color(0xFFF0FDFA);
}
