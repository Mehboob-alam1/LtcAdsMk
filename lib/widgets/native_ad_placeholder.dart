import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/remote_config_service.dart';
import '../services/smart_ad_manager.dart';

/// Loads and displays a native ad (AdMob or AdX, whichever loads first).
/// Shows a loading or placeholder state until the ad is ready.
class NativeAdPlaceholder extends StatefulWidget {
  const NativeAdPlaceholder({super.key});

  @override
  State<NativeAdPlaceholder> createState() => _NativeAdPlaceholderState();
}

class _NativeAdPlaceholderState extends State<NativeAdPlaceholder> {
  NativeAd? _ad;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (RemoteConfigService.instance.nativeAdsEnabled) {
      SmartAdManager.instance.loadNative(
        onResult: (ad) {
          if (!mounted) {
            ad?.dispose();
            return;
          }
          setState(() {
            _ad = ad;
            _loading = false;
            _failed = ad == null;
          });
        },
      );
    } else {
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    // Do not dispose _ad: SmartAdManager owns it and may reuse for other placeholders
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!RemoteConfigService.instance.nativeAdsEnabled || _failed) {
      return const SizedBox.shrink();
    }
    if (_loading) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade600),
          ),
        ),
      );
    }
    if (_ad == null) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _ad!),
    );
  }
}
