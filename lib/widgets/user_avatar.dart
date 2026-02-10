import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.size = 40,
    this.showBorder = false,
    this.borderWidth = 2,
    this.borderColor,
  });

  final double size;
  final bool showBorder;
  final double borderWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final photoUrl = user?.photoURL;
    final name = user?.displayName?.trim() ?? '';
    final initials = name.isNotEmpty ? name[0] : 'U';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showBorder
            ? null
            : const LinearGradient(
          colors: [
            AppColors.primaryLightBg,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: showBorder
            ? Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.8),
          width: borderWidth,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar(initials, size);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialsAvatar(initials, size);
          },
        )
            : _buildInitialsAvatar(initials, size),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLightBg,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}