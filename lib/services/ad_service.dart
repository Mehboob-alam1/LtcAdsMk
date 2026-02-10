import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'smart_ad_manager.dart';

/// Facade for rewarded and interstitial ads. Delegates to [SmartAdManager] (loads both AdMob and AdX per slot; shows whichever loads first).
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static SmartAdManager get _manager => SmartAdManager.instance;

  /// Initialize Mobile Ads SDK. Prefer calling [SmartAdManager.initialize] from main (already done).
  static Future<void> initialize() async {
    await SmartAdManager.initialize();
  }

  void loadRewardedAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    _manager.loadRewarded(onLoaded: onLoaded, onFailed: onFailed);
  }

  void loadInterstitialAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    _manager.loadInterstitial(onLoaded: onLoaded, onFailed: onFailed);
  }

  bool get isRewardedAdReady => _manager.isRewardedReady;
  bool get isInterstitialAdReady => _manager.isInterstitialReady;

  Future<void> showRewardedAd({
    required void Function() onReward,
    void Function(String)? onFailed,
  }) async {
    await _manager.showRewarded(onReward: onReward, onFailed: onFailed);
  }

  Future<void> showInterstitialAd({void Function()? onClosed}) async {
    await _manager.showInterstitial(onClosed: onClosed);
  }

  Future<void> tryShowInterstitialRandomly() async {
    await _manager.tryShowInterstitialRandomly();
  }
}
