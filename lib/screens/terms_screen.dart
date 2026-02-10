import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/native_ad_placeholder.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: const Color(0xFFF9F4F7),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Acceptance of terms', 'By downloading, installing, or using the GIGA ETH Mining app, you agree to these Terms and Conditions. If you do not agree, do not use the app.'),
          _section('Service description', 'GIGA ETH Mining is an app that simulates mining activity and rewards users with in-app balance. Withdrawals are subject to minimum thresholds and approval. The service is provided "as is."'),
          _section('Eligibility', 'You must be of legal age in your jurisdiction to use this app. You are responsible for compliance with local laws regarding cryptocurrency and rewards.'),
          _section('User account', 'You are responsible for maintaining the confidentiality of your account. You must provide accurate information and notify us of any unauthorized use.'),
          _section('Prohibited conduct', 'You may not use the app for illegal purposes, to abuse or exploit the system, or to violate any applicable laws. We reserve the right to suspend or terminate accounts that violate these terms.'),
          _section('Limitation of liability', 'To the fullest extent permitted by law, we are not liable for any indirect, incidental, or consequential damages arising from your use of the app. Our total liability shall not exceed the amount you have earned in the app in the past 12 months.'),
          _section('Changes to terms', 'We may modify these terms at any time. Continued use of the app after changes constitutes acceptance. We encourage you to review the terms periodically.'),
          _section('Contact', 'For questions about these Terms and Conditions, please contact us through the app or our designated support channel.'),
          const SizedBox(height: 20),
          const NativeAdPlaceholder(),
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
