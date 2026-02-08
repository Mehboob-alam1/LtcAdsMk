import 'package:flutter/material.dart';

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
        color: isLocked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? Colors.grey.shade300
              : Colors.purple.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLocked
                ? Colors.black.withOpacity(0.02)
                : Colors.purple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                        Colors.grey.shade200,
                        Colors.grey.shade300,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : LinearGradient(
                      colors: [
                        const Color(0xFFEDE2F4),
                        const Color(0xFFE5D4F0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isLocked
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.memory,
                    color: isLocked
                        ? Colors.grey.shade600
                        : const Color(0xFF7B47C6),
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
                                    ? Colors.grey.shade600
                                    : Colors.black,
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
                              color: Colors.purple.shade400,
                            ),
                          if (isLocked) const SizedBox(width: 4),
                          Text(
                            isLocked ? 'Unlock in Shop' : 'Status: $status',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLocked
                                  ? Colors.purple.shade600
                                  : Colors.grey.shade600,
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
                            ? Colors.grey.shade200
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isLocked
                              ? Colors.grey.shade600
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
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                if (isLocked) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.purple.shade400,
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