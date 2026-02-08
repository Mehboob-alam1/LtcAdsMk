import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../models/transaction_item.dart';
import '../models/user_stats.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Profile Header Card - Modern & Elegant
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppGradients.magenta,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
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

        const SizedBox(height: 16),
        const NativeAdPlaceholder(),
        const SizedBox(height: 20),

        // Overview Section Header
        _buildSectionHeader(context, 'Overview', Icons.insights),
        const SizedBox(height: 10),

        // Stats Grid - Modern Cards
        StreamBuilder<UserStats>(
          stream: DatabaseService.instance.statsStream(user.uid),
          builder: (context, statsSnap) {
            final stats = statsSnap.data;
            final balance = stats?.balanceBtc ?? 0.0;
            return _modernInfoCard(
              icon: Icons.account_balance_wallet,
              iconColor: Colors.green,
              label: 'Lifetime Earnings',
              value: '${MiningConstants.formatBtcFull(balance)} BTC',
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
            Color boostColor = Colors.grey;

            if (hasBoost && boostEndsAt is num) {
              final end = DateTime.fromMillisecondsSinceEpoch(
                  (boostEndsAt as num).toInt());
              boostLabel =
              '2x until ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
              boostIcon = Icons.bolt;
              boostColor = Colors.amber;
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
          iconColor: Colors.blue,
          label: 'Min. Withdraw',
          value:
          '${MiningConstants.formatBtcFull(MiningConstants.minWithdrawBtc)} BTC',
        ),

        const SizedBox(height: 20),

        // Recent Withdrawals Section
        _buildSectionHeader(context, 'Recent Withdrawals', Icons.history),
        const SizedBox(height: 10),

        StreamBuilder<List<TransactionItem>>(
          stream: DatabaseService.instance.withdrawalsStream(user.uid),
          builder: (context, wSnap) {
            final withdrawals = wSnap.data ?? [];
            if (withdrawals.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No withdrawals yet. Reach ${MiningConstants.formatBtcFull(MiningConstants.minWithdrawBtc)} BTC to withdraw.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.purple.shade700,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}