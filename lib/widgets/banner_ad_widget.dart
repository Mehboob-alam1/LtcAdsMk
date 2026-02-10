import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/remote_config_service.dart';
import '../services/smart_ad_manager.dart';

/// Banner ad via [SmartAdManager]: loads from both AdMob and AdX; shows whichever loads first.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  AdWithView? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (RemoteConfigService.instance.bannerAdsEnabled) {
      SmartAdManager.instance.loadBanner(
        size: AdSize.banner,
        onResult: (ad) {
          if (!mounted) {
            ad?.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad;
            _loaded = ad != null;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!RemoteConfigService.instance.bannerAdsEnabled) {
      return const SizedBox.shrink();
    }
    if (!_loaded || _bannerAd == null) {
      return const SizedBox(
        height: 50,
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return SizedBox(
      height: 50,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
