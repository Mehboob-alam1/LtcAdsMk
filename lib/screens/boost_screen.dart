import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/boost_tile.dart';
import '../widgets/native_ad_placeholder.dart';

/// Real boost packs: watch 1 ad → apply 2x mining for the given duration.
/// Durations kept realistic so monthly earnings stay under the app cap (~\$100 value).
class BoostScreen extends StatelessWidget {
  const BoostScreen({super.key});

  static const double _boostMultiplier = 2.0;

  Future<void> _watchAdAndApplyBoost(
      BuildContext context, {
        required String packName,
        required int durationMinutes,
      }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    if (!AdService.instance.isRewardedAdReady) {
      AdService.instance.loadRewardedAd(
        onLoaded: () {
          if (context.mounted) {
            _showAdAndApply(context, user.uid, packName, durationMinutes);
          }
        },
        onFailed: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ad not ready. Try again soon.'),
                backgroundColor: const Color(0xFFFF6B00),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      );
      return;
    }
    await _showAdAndApply(context, user.uid, packName, durationMinutes);
  }

  Future<void> _showAdAndApply(
      BuildContext context,
      String uid,
      String packName,
      int durationMinutes,
      ) async {
    await AdService.instance.showRewardedAd(
      onReward: () async {
        await DatabaseService.instance.applyBoost(
          uid,
          multiplier: _boostMultiplier,
          durationMinutes: durationMinutes,
        );
        final hours = durationMinutes >= 60
            ? '${durationMinutes ~/ 60}h'
            : '${durationMinutes}min';
        await NotificationService.instance.showBoostActivated(
          title: 'Boost activated',
          body:
          '$packName: ${_boostMultiplier}x mining for $hours. You\'re earning faster!',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$packName active! ${_boostMultiplier}x mining for $hours.'),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      onFailed: (msg) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ad failed: $msg'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Boost',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          const NativeAdPlaceholder(),
          const SizedBox(height: 16),
          _buildBoostCard(
            context,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            icon: Icons.flash_on,
            title: 'Power Surge ×2',
            duration: '1 hour',
            onTap: () {
              AdService.instance.tryShowInterstitialRandomly();
              _watchAdAndApplyBoost(
                context,
                packName: 'Power Surge',
                durationMinutes: 60,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildBoostCard(
            context,
            gradient: const LinearGradient(
              colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
            ),
            icon: Icons.rocket_launch,
            title: 'Turbo ×2',
            duration: '3 hours',
            onTap: () {
              AdService.instance.tryShowInterstitialRandomly();
              _watchAdAndApplyBoost(
                context,
                packName: 'Turbo',
                durationMinutes: 180,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildBoostCard(
            context,
            gradient: const LinearGradient(
              colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
            ),
            icon: Icons.auto_awesome,
            title: 'Mega ×2',
            duration: '6 hours',
            onTap: () {
              AdService.instance.tryShowInterstitialRandomly();
              _watchAdAndApplyBoost(
                context,
                packName: 'Mega',
                durationMinutes: 360,
              );
            },
          ),
          const SizedBox(height: 20),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Boost Packs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Watch ads to multiply your mining rate and earn faster',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBoostCard(
      BuildContext context, {
        required Gradient gradient,
        required IconData icon,
        required String title,
        required String duration,
        required VoidCallback onTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '2× mining rate for $duration',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: gradient.colors.first,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Watch',
                        style: TextStyle(
                          color: gradient.colors.first,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF0F3460),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Boosts multiply your mining rate. Stack them with your current mining session for maximum earnings!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
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