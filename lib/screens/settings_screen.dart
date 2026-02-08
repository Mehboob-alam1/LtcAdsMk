import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../widgets/native_ad_placeholder.dart';
import 'disclaimer_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF9F4F7),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // App Section
          _buildSectionHeader('App', Icons.settings),
          const SizedBox(height: 10),
          _modernSettingsTile(
            context,
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            title: 'About',
            subtitle:
            'GIGA BTC Mining • Min. withdraw ${MiningConstants.formatBtcFull(MiningConstants.minWithdrawBtc)} BTC',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'GIGA BTC Mining',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Mine BTC, watch ads for boosts.',
              );
            },
          ),
          _modernSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            subtitle: 'Mining start & end alerts',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications are enabled for mining sessions.'),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          const NativeAdPlaceholder(),
          const SizedBox(height: 20),

          // Legal Section
          _buildSectionHeader('Legal', Icons.gavel),
          const SizedBox(height: 10),
          _modernSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.purple,
            title: 'Privacy Policy',
            subtitle: 'How we collect and use your data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          _modernSettingsTile(
            context,
            icon: Icons.description_outlined,
            iconColor: Colors.green,
            title: 'Terms & Conditions',
            subtitle: 'Terms of use for the app',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          _modernSettingsTile(
            context,
            icon: Icons.warning_amber_outlined,
            iconColor: Colors.amber,
            title: 'Disclaimer',
            subtitle: 'Important notices and limitations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _modernSettingsTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon Container
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
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}