import 'package:flutter/material.dart';

import '../constants/shop_items.dart';
import '../models/user_stats.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../theme/app_gradients.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_placeholder.dart';
import 'lucky_spin_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static String _adsKey(String itemId) {
    return 'adsFor${itemId[0].toUpperCase()}${itemId.substring(1)}';
  }

  static bool _unlocked(Map<String, dynamic> data, ShopItem item) {
    switch (item.id) {
      case 'rig1':
        return data['rig1Unlocked'] == true;
      case 'rig2':
        return data['rig2Unlocked'] == true;
      case 'rig3':
        return data['rig3Unlocked'] == true;
      case 'megaBoost':
        return data['megaBoostUnlocked'] == true;
      case 'autoMiningDay':
        return data['autoMiningDayUnlocked'] == true &&
            (data['usedAutoMiningDayAt'] is! num ||
                (data['usedAutoMiningDayAt'] as num).toInt() <= 0);
      case 'doubleSession':
        return data['doubleSessionAvailable'] == true;
      default:
        return data['${item.id}Unlocked'] == true;
    }
  }

  static int _progress(Map<String, dynamic> data, ShopItem item) {
    final v = data[_adsKey(item.id)];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Sign in to view shop.'));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Header Card - Compact & Modern
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppGradients.emerald,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unlock rigs, boosters & features',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
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
        const SizedBox(height: 16),

        // Lucky Spin - Compact Version
        _LuckySpinEntry(uid: user.uid),

        const SizedBox(height: 20),

        // Rigs Section
        _buildSectionHeader(context, 'Rigs', Icons.memory),
        const SizedBox(height: 10),
        StreamBuilder<Map<String, dynamic>>(
          stream: DatabaseService.instance.shopProgressStream(user.uid),
          builder: (context, shopSnap) {
            final data = shopSnap.data ?? {};
            return Column(
              children: ShopItem.rigs
                  .map((item) => _ShopItemCard(
                item: item,
                progress: _progress(data, item),
                unlocked: _unlocked(data, item),
                onWatchAd: () =>
                    _watchAdForItem(context, user.uid, item, 1),
                onUse: null,
              ))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 20),

        // Boosters Section
        _buildSectionHeader(context, 'Boosters', Icons.bolt),
        const SizedBox(height: 10),
        StreamBuilder<Map<String, dynamic>>(
          stream: DatabaseService.instance.shopProgressStream(user.uid),
          builder: (context, shopSnap) {
            final data = shopSnap.data ?? {};
            return Column(
              children: ShopItem.boosters
                  .map((item) => _ShopItemCard(
                item: item,
                progress: _progress(data, item),
                unlocked: _unlocked(data, item),
                onWatchAd: () =>
                    _watchAdForItem(context, user.uid, item, 1),
                onUse: item.id == 'megaBoost'
                    ? () => _useMegaBoost(context, user.uid)
                    : null,
              ))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 20),

        // Features Section
        _buildSectionHeader(context, 'Features', Icons.auto_awesome),
        const SizedBox(height: 10),
        StreamBuilder<UserStats>(
          stream: DatabaseService.instance.statsStream(user.uid),
          builder: (context, statsSnap) {
            final balance = statsSnap.data?.balanceBtc ?? 0.0;
            return StreamBuilder<Map<String, dynamic>>(
              stream: DatabaseService.instance.shopProgressStream(user.uid),
              builder: (context, shopSnap) {
                final data = shopSnap.data ?? {};
                return Column(
                  children: ShopItem.features.map((item) {
                    VoidCallback? onUse;
                    if (item.id == 'autoMiningDay') {
                      onUse = () =>
                          _useAutoMiningPack(context, user.uid, balance);
                    } else if (item.id == 'doubleSession') {
                      onUse = () => _useDoubleSession(context, user.uid);
                    }
                    return _ShopItemCard(
                      item: item,
                      progress: _progress(data, item),
                      unlocked: _unlocked(data, item),
                      onWatchAd: () =>
                          _watchAdForItem(context, user.uid, item, 1),
                      onUse: onUse,
                    );
                  }).toList(),
                );
              },
            );
          },
        ),

        const SizedBox(height: 20),
        const BannerAdWidget(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.blue.shade700,
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

  Future<void> _watchAdForItem(
      BuildContext context, String uid, ShopItem item, int amount) async {
    if (!AdService.instance.isRewardedAdReady) {
      AdService.instance.loadRewardedAd(onLoaded: () {
        if (context.mounted) _showAdForItem(context, uid, item, amount);
      }, onFailed: () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad not ready. Try again soon.')),
          );
        }
      });
      return;
    }
    await _showAdForItem(context, uid, item, amount);
  }

  Future<void> _showAdForItem(
      BuildContext context, String uid, ShopItem item, int amount) async {
    await AdService.instance.showRewardedAd(
      onReward: () async {
        int newCount;
        if (item.id == 'autoMiningDay') {
          newCount =
          await DatabaseService.instance.incrementAutoMiningDayAds(uid);
        } else {
          newCount = await DatabaseService.instance
              .addShopProgress(uid, item.id, amount);
        }
        if (newCount >= item.adsRequired) {
          await NotificationService.instance.showShopNotification(
            title: 'Unlocked!',
            body: '${item.name} is yours. ${item.description}',
          );
        }
        if (context.mounted) {
          if (newCount >= item.adsRequired) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} unlocked!'),
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                  Text('$newCount/${item.adsRequired} ads. Keep going!')),
            );
          }
        }
      },
      onFailed: (msg) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ad failed: $msg')),
          );
        }
      },
    );
  }

  Future<void> _useAutoMiningPack(
      BuildContext context, String uid, double balance) async {
    final ok =
    await DatabaseService.instance.useAutoMiningDayPack(uid, balance);
    if (!context.mounted) return;
    if (ok) {
      final sessionEndsAt = DateTime.now().add(const Duration(hours: 24));
      await NotificationService.instance.showMiningStarted(
        sessionHours: 24,
        sessionEndsAt: sessionEndsAt,
      );
      await NotificationService.instance.showShopNotification(
        title: 'Auto mining started',
        body:
        '24-hour mining session is running. Check Dashboard for your balance.',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('24-hour auto mining started! Check Dashboard.'),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pack not available.')),
      );
    }
  }

  Future<void> _useMegaBoost(BuildContext context, String uid) async {
    final ok = await DatabaseService.instance.useMegaBoost(uid);
    if (!context.mounted) return;
    if (ok) {
      await NotificationService.instance.showShopNotification(
        title: 'Mega Boost active',
        body: '2x mining rate for 1 hour. You\'re earning faster!',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mega Boost active: 2x for 1 hour!'),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mega Boost not available.')),
      );
    }
  }

  Future<void> _useDoubleSession(BuildContext context, String uid) async {
    final ok = await DatabaseService.instance.useDoubleSession(uid);
    if (!context.mounted) return;
    if (ok) {
      await NotificationService.instance.showShopNotification(
        title: 'Double Session active',
        body: 'Your next Start Mining will run for 8 hours instead of 4.',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Double Session active! Next Start Mining will run 8 hours.'),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Double Session not available.')),
      );
    }
  }
}

class _LuckySpinEntry extends StatelessWidget {
  const _LuckySpinEntry({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AdService.instance.tryShowInterstitialRandomly();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LuckySpinScreen(uid: uid)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade600,
                Colors.orange.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.casino,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lucky Spin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Watch 2 ads to unlock a spin',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.progress,
    required this.unlocked,
    required this.onWatchAd,
    this.onUse,
  });

  final ShopItem item;
  final int progress;
  final bool unlocked;
  final VoidCallback onWatchAd;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final canUse = unlocked && (onUse != null);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: item.type == 'rig'
            ? AppGradients.blue
            : (item.type == 'booster'
            ? AppGradients.emerald
            : AppGradients.magenta),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (item.type == 'rig'
                ? Colors.blue
                : (item.type == 'booster' ? Colors.green : Colors.purple))
                .withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.type == 'rig'
                      ? Icons.memory
                      : (item.type == 'booster'
                      ? Icons.bolt
                      : Icons.auto_awesome),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!unlocked) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (item.adsRequired > 0)
                            ? (progress / item.adsRequired).clamp(0.0, 1.0)
                            : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$progress/${item.adsRequired}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onWatchAd,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: item.type == 'rig'
                      ? const Color(0xFF1466FF)
                      : (item.type == 'booster'
                      ? Colors.green.shade700
                      : Colors.purple.shade700),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_filled, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Watch ad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (canUse) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUse,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: item.type == 'rig'
                      ? const Color(0xFF1466FF)
                      : (item.type == 'booster'
                      ? Colors.green.shade700
                      : Colors.purple.shade700),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      item.id == 'autoMiningDay'
                          ? 'Start 24h mining'
                          : (item.id == 'doubleSession'
                          ? 'Use for 8h session'
                          : 'Use'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Unlocked',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}