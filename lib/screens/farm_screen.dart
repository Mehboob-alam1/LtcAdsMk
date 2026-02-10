import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../constants/shop_items.dart';
import '../models/user_stats.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/ad_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_placeholder.dart';
import '../widgets/rig_tile.dart';

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key, this.onOpenShop});

  final VoidCallback? onOpenShop;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Sign in to view your farm.'));
    }
    return StreamBuilder<UserStats>(
      stream: DatabaseService.instance.statsStream(user.uid),
      builder: (context, statsSnap) {
        final stats = statsSnap.data ?? UserStats.initial();
                        return StreamBuilder<Map<String, dynamic>>(
                          stream: DatabaseService.instance.miningStream(user.uid),
                          builder: (context, miningSnap) {
                            final mining = miningSnap.data ?? {'active': false};
                            final active = mining['active'] == true;
            return StreamBuilder<Map<String, dynamic>>(
              stream: DatabaseService.instance.shopProgressStream(user.uid),
              builder: (context, shopSnap) {
                final shop = shopSnap.data ?? {};
                final rig1Unlocked = shop['rig1Unlocked'] == true;
                final rig2Unlocked = shop['rig2Unlocked'] == true;
                final rig3Unlocked = shop['rig3Unlocked'] == true;
                final activeRigsCount = [rig1Unlocked, rig2Unlocked, rig3Unlocked]
                    .where((v) => v)
                    .length;
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.screenPaddingH,
                    vertical: AppTheme.screenPaddingV,
                  ),
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.sectionSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mining Farm',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your ETH mining rigs',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mining Status Card - ETH theme
                    Container(
                      padding: AppTheme.cardPadding,
                      decoration: BoxDecoration(
                        gradient: AppGradients.eth,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        boxShadow: AppTheme.balanceCardShadow,
                      ),
                      child: Column(
                        children: [
                          // Status Badge & Efficiency Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Efficiency',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${stats.rigEfficiency}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: active
                                        ? Colors.greenAccent.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.greenAccent
                                            : Colors.white60,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      active ? 'Mining' : 'Paused',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Balance (so user sees balance when mining)
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Balance: ${MiningConstants.formatEthFull(stats.balanceBtc)} ETH',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Stats Grid - Compact
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.bolt,
                                  label: 'Power',
                                  value: '3.2 MW',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.ac_unit,
                                  label: 'Cooling',
                                  value: 'Optimal',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const NativeAdPlaceholder(),
                    const SizedBox(height: 24),

                    // Rigs Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Rigs',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Unlock more in the Shop',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$activeRigsCount/${ShopItem.rigs.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Rigs List
                    ...ShopItem.rigs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final unlocked = index == 0
                          ? rig1Unlocked
                          : (index == 1 ? rig2Unlocked : rig3Unlocked);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RigTile(
                          name: item.name,
                          status: unlocked ? 'Online' : 'Locked',
                          rate: unlocked ? 'Active' : '—',
                          temp: unlocked ? '—' : '—',
                          isLocked: !unlocked,
                          bonusLabel: unlocked
                              ? '+${item.rigBonusPercent.toInt()}% rate'
                              : null,
                          onTap: onOpenShop,
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                    const BannerAdWidget(),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}