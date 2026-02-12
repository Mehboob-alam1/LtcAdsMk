import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/native_ad_placeholder.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFFF9F4F7),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Last updated', 'Please refer to the effective date at the bottom of this policy.'),
          _section('Information we collect', 'We collect information you provide when you use the GIGA LTC Mining app, including account details, mining session data, and balance information. We may also collect device information and usage data to improve our services.'),
          _section('How we use your information', 'Your information is used to operate the mining service, process withdrawals, show relevant ads, and improve the app. We do not sell your personal data to third parties.'),
          _section('Data storage', 'Data is stored securely using Firebase. Mining and balance data is associated with your account and used only to provide the service.'),
          _section('Third-party services', 'We use Google Mobile Ads for advertisements. Ad providers may collect data according to their own privacy policies. We use Firebase for authentication and database storage.'),
          _section('Your rights', 'You may request access to or deletion of your data. Contact us through the app or support channels for such requests.'),
          _section('Changes', 'We may update this Privacy Policy from time to time. Continued use of the app after changes constitutes acceptance.'),
          const SizedBox(height: 20),
          const NativeAdPlaceholder(),
          const SizedBox(height: 24),
          Text('Effective date: 2025', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
