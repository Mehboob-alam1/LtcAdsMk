import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../models/transaction_item.dart';
import '../models/user_stats.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../widgets/activity_tile.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_placeholder.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Sign in to view profile.'));
    }
    final displayName =
        user.displayName ?? (user.isAnonymous ? 'Guest Miner' : 'Miner');
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.screenPaddingH,
        vertical: AppTheme.screenPaddingV,
      ),
      children: [
        // Profile Header Card - teal theme
        Container(
          padding: AppTheme.cardPadding,
          decoration: BoxDecoration(
            gradient: AppGradients.eth,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.balanceCardShadow,
          ),
          child: Row(
            children: [
              // Avatar with border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const UserAvatar(size: 56),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Platinum Tier',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.cardSpacing),
        const NativeAdPlaceholder(),
        const SizedBox(height: AppTheme.sectionSpacing),

        // Overview Section Header
        _buildSectionHeader(context, 'Overview', Icons.insights),
        const SizedBox(height: 12),

        // Stats Grid - teal theme cards
        StreamBuilder<UserStats>(
          stream: DatabaseService.instance.statsStream(user.uid),
          builder: (context, statsSnap) {
            final stats = statsSnap.data;
            final balance = stats?.balanceBtc ?? 0.0;
            return _modernInfoCard(
              icon: Icons.account_balance_wallet,
              iconColor: AppColors.success,
              label: 'Lifetime Earnings',
              value: '${MiningConstants.formatBtcFull(balance)} LTC',
            );
          },
        ),

        StreamBuilder<Map<String, dynamic>>(
          stream: DatabaseService.instance.miningStream(user.uid),
          builder: (context, miningSnap) {
            final data = miningSnap.data;
            final boostEndsAt = data?['boostEndsAt'];
            final now = DateTime.now().millisecondsSinceEpoch;
            final hasBoost =
                boostEndsAt is num && (boostEndsAt as num).toInt() > now;
            String boostLabel = 'None';
            IconData boostIcon = Icons.bolt_outlined;
            Color boostColor = AppColors.textSecondary;

            if (hasBoost && boostEndsAt is num) {
              final end = DateTime.fromMillisecondsSinceEpoch(
                  (boostEndsAt as num).toInt());
              boostLabel =
              '2x until ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
              boostIcon = Icons.bolt;
              boostColor = AppColors.primary;
            }

            return _modernInfoCard(
              icon: boostIcon,
              iconColor: boostColor,
              label: 'Active Boosts',
              value: boostLabel,
            );
          },
        ),

        _modernInfoCard(
          icon: Icons.download,
          iconColor: AppColors.primary,
          label: 'Min. Withdraw',
          value:
          '~\$100 worth of LTC',
        ),

        const SizedBox(height: AppTheme.sectionSpacing),

        // Recent Withdrawals Section
        _buildSectionHeader(context, 'Recent Withdrawals', Icons.history),
        const SizedBox(height: 12),

        StreamBuilder<List<TransactionItem>>(
          stream: DatabaseService.instance.withdrawalsStream(user.uid),
          builder: (context, wSnap) {
            final withdrawals = wSnap.data ?? [];
            if (withdrawals.isEmpty) {
              return Container(
                padding: AppTheme.cardPadding,
                decoration: AppTheme.cardDecoration(color: AppColors.cardTint),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No withdrawals yet. Reach ~\$100 worth of LTC to withdraw.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final sorted = List<TransactionItem>.from(withdrawals)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return Column(
              children: sorted.take(5).map((w) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ActivityTile(
                    title: w.title.isNotEmpty ? w.title : 'Withdrawal',
                    subtitle: w.status,
                    value: '-${w.amount}',
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 20),
        const BannerAdWidget(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLightBg,
            borderRadius: BorderRadius.circular(AppTheme.chipRadius),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _modernInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}