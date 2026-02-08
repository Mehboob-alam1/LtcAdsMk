import 'package:flutter/material.dart';

import '../widgets/native_ad_placeholder.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disclaimer'),
        backgroundColor: const Color(0xFFF9F4F7),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('No financial advice', 'The GIGA BTC Mining app is for entertainment and educational purposes only. Nothing in the app constitutes financial, investment, or legal advice. You should not rely on the app for any financial decisions.'),
          _section('Simulated mining', 'Mining and rewards in this app are simulated. The app does not perform actual cryptocurrency mining. Balances and payouts are in-app only and subject to the app\'s terms and withdrawal rules.'),
          _section('No guarantee', 'We do not guarantee availability of the service, accuracy of displayed data, or that withdrawals will be processed within any specific time. Service may be modified or discontinued at any time.'),
          _section('Third-party services', 'The app may use third-party services (e.g. ads, analytics). We are not responsible for the content or policies of third parties. Your use of those services is at your own risk.'),
          _section('User responsibility', 'You use the app at your own risk. We are not liable for any loss or damage arising from your use of the app, including but not limited to loss of data, account access, or in-app balance.'),
          const SizedBox(height: 20),
          const NativeAdPlaceholder(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              'By using this app, you acknowledge that you have read, understood, and agree to this Disclaimer.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ),
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
              color: Color(0xFF2E123B),
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
