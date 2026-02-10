import 'package:flutter/material.dart';
import 'package:btc_ads/theme/app_colors.dart';
import 'package:btc_ads/theme/app_theme.dart';

class RigTile extends StatelessWidget {
  const RigTile({
    super.key,
    required this.name,
    required this.status,
    required this.rate,
    required this.temp,
    this.isLocked = false,
    this.bonusLabel,
    this.onTap,
  });

  final String name;
  final String status;
  final String rate;
  final String temp;
  final bool isLocked;
  final String? bonusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLocked ? AppColors.cardTint : AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isLocked ? AppColors.border : AppColors.primary.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: isLocked
            ? AppTheme.cardShadow
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: AppTheme.cardPadding,
            child: Row(
              children: [
                // Icon Container
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: isLocked
                        ? LinearGradient(
                            colors: [
                              AppColors.border,
                              AppColors.textSecondary.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.primaryLightBg,
                              AppColors.primaryLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                    boxShadow: [
                      BoxShadow(
                        color: isLocked
                            ? AppColors.border.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.memory,
                    color: isLocked
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isLocked
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!isLocked && status.toLowerCase() == 'online')
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isLocked)
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          if (isLocked) const SizedBox(width: 4),
                          Text(
                            isLocked ? 'Unlock in Shop' : 'Status: $status',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLocked
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: isLocked
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stats Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? AppColors.border
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isLocked
                              ? AppColors.textSecondary
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (bonusLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 10,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              bonusLabel!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!isLocked)
                      Text(
                        temp,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (isLocked) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}