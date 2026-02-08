import 'package:flutter/material.dart';

import '../theme/app_gradients.dart';

class RewardTile extends StatelessWidget {
  const RewardTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onTap,
    this.isClaimed = false,
  });

  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onTap;
  final bool isClaimed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed
              ? Colors.grey.shade300
              : Colors.purple.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isClaimed
                ? Colors.black.withOpacity(0.02)
                : Colors.purple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon Container with Gradient
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isClaimed
                        ? LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : AppGradients.magenta,
                    boxShadow: [
                      BoxShadow(
                        color: isClaimed
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.purple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isClaimed ? Icons.check_circle : Icons.card_giftcard,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isClaimed
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isClaimed
                              ? Colors.grey.shade500
                              : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Value Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isClaimed
                        ? LinearGradient(
                      colors: [
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : LinearGradient(
                      colors: [
                        Colors.purple.shade50,
                        Colors.purple.shade100,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isClaimed
                          ? Colors.grey.shade300
                          : Colors.purple.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isClaimed) ...[
                        Icon(
                          Icons.stars_rounded,
                          size: 14,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isClaimed
                              ? Colors.grey.shade600
                              : Colors.purple.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isClaimed) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Claimed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
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