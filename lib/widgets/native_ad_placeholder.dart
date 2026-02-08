import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/remote_config_service.dart';
import '../services/smart_ad_manager.dart';

/// Placeholder for native ad slot. When native_ads_enabled is true, shows a reserved slot.
/// For a real native ad use [SmartAdManager.instance.loadNative] (template style, no platform factory)
/// and display the returned [NativeAd] with [AdWidget].
class NativeAdPlaceholder extends StatelessWidget {
  const NativeAdPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    if (!RemoteConfigService.instance.nativeAdsEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          'Ad',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ),
    );
  }
}
