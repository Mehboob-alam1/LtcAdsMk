import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Main app gradient (teal).
class AppGradients {
  static const eth = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const btc = LinearGradient(
    colors: [Color(0xFFFF7A1A), Color(0xFFE63B3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const magenta = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const blue = LinearGradient(
    colors: [Color(0xFF00D1FF), Color(0xFF1466FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const emerald = LinearGradient(
    colors: [Color(0xFF7CFFCB), Color(0xFF1C8BBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
