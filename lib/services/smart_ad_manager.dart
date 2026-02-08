import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'remote_config_service.dart';

/// Central ad mediation: ADX first, then AdMob. All unit IDs from Firebase Remote Config.
/// Singleton; initialize early from main() after Firebase & Remote Config.
class SmartAdManager {
  SmartAdManager._();

  static final SmartAdManager instance = SmartAdManager._();

  final RemoteConfigService _config = RemoteConfigService.instance;

  bool _sdkInitialized = false;

  // Interstitial & Rewarded: hold loaded ads
  InterstitialAd? _interstitialAd;
  bool _interstitialLoaded = false;
  RewardedAd? _rewardedAd;
  bool _rewardedLoaded = false;
  AppOpenAd? _appOpenAd;
  bool _appOpenLoaded = false;
  DateTime? _lastInterstitialShownAt;
  DateTime? _lastAppOpenShownAt;

  // Native: hold last loaded native ad for UI
  NativeAd? _nativeAd;
  bool _nativeLoaded = false;

  bool get isSdkInitialized => _sdkInitialized;
  bool get isInterstitialReady => _interstitialLoaded && _interstitialAd != null;
  bool get isRewardedReady => _rewardedLoaded && _rewardedAd != null;
  bool get isAppOpenReady => _appOpenLoaded && _appOpenAd != null;
  bool get isNativeReady => _nativeLoaded && _nativeAd != null;
  DateTime? get lastInterstitialShownAt => _lastInterstitialShownAt;
  /// When the app-open ad was last shown (for cooldown / policy).
  DateTime? get lastAppOpenShownAt => _lastAppOpenShownAt;

  /// Initialize Mobile Ads SDK. Call once from main() after Firebase/Remote Config.
  static Future<void> initialize() async {
    if (instance._sdkInitialized) return;
    await MobileAds.instance.initialize();
    instance._sdkInitialized = true;
  }

  bool get _isAndroid => !Platform.isIOS;
  bool get _isIOS => Platform.isIOS;

  String get _bannerAdx => _isAndroid ? _config.bannerAdxAndroid : _config.bannerAdxIos;
  String get _bannerAdmob => _isAndroid ? _config.bannerAdmobAndroid : _config.bannerAdmobIos;
  String get _nativeAdx => _isAndroid ? _config.nativeAdxAndroid : _config.nativeAdxIos;
  String get _nativeAdmob => _isAndroid ? _config.nativeAdmobAndroid : _config.nativeAdmobIos;
  String get _interstitialAdx => _isAndroid ? _config.interstitialAdxAndroid : _config.interstitialAdxIos;
  String get _interstitialAdmob => _isAndroid ? _config.interstitialAdmobAndroid : _config.interstitialAdmobIos;
  String get _rewardedAdx => _isAndroid ? _config.rewardedAdxAndroid : _config.rewardedAdxIos;
  String get _rewardedAdmob => _isAndroid ? _config.rewardedAdmobAndroid : _config.rewardedAdmobIos;
  String get _appOpenAdx => _isAndroid ? _config.appOpenAdxAndroid : _config.appOpenAdxIos;
  String get _appOpenAdmob => _isAndroid ? _config.appOpenAdmobAndroid : _config.appOpenAdmobIos;

  // --- Banner: ADX then AdMob ---
  void loadBanner({
    required AdSize size,
    required void Function(BannerAd?) onResult,
  }) {
    if (!_config.bannerAdsEnabled) {
      onResult(null);
      return;
    }
    void tryLoad(String adUnitId, {bool isAdmob = false}) {
      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loadedAd) => onResult(loadedAd as BannerAd),
          onAdFailedToLoad: (failedAd, error) {
            failedAd.dispose();
            if (isAdmob) {
              onResult(null);
            } else {
              tryLoad(_bannerAdmob, isAdmob: true);
            }
          },
        ),
      );
      bannerAd.load();
    }
    tryLoad(_bannerAdx);
  }

  // --- Native: ADX then AdMob (uses native template, no platform factory) ---
  void loadNative({
    NativeTemplateStyle? nativeTemplateStyle,
    void Function(NativeAd?)? onResult,
  }) {
    if (!_config.nativeAdsEnabled) {
      onResult?.call(null);
      return;
    }
    final style = nativeTemplateStyle ?? NativeTemplateStyle(templateType: TemplateType.medium);
    void tryLoad(String adUnitId, {bool isAdmob = false}) {
      final ad = NativeAd(
        adUnitId: adUnitId,
        request: const AdRequest(),
        nativeTemplateStyle: style,
        listener: NativeAdListener(
          onAdLoaded: (loadedAd) {
            _nativeAd?.dispose();
            _nativeAd = loadedAd as NativeAd;
            _nativeLoaded = true;
            onResult?.call(loadedAd as NativeAd);
          },
          onAdFailedToLoad: (failedAd, error) {
            failedAd.dispose();
            if (isAdmob) {
              onResult?.call(null);
            } else {
              tryLoad(_nativeAdmob, isAdmob: true);
            }
          },
        ),
      );
      ad.load();
    }
    tryLoad(_nativeAdx);
  }

  NativeAd? get currentNativeAd => _nativeLoaded ? _nativeAd : null;

  // --- Interstitial: ADX then AdMob ---
  void loadInterstitial({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (!_config.interstitialAdsEnabled) {
      onFailed?.call();
      return;
    }
    void tryLoad(String adUnitId, {bool isAdmob = false}) {
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialLoaded = true;
            onLoaded?.call();
          },
          onAdFailedToLoad: (error) {
            if (isAdmob) {
              onFailed?.call();
            } else {
              tryLoad(_interstitialAdmob, isAdmob: true);
            }
          },
        ),
      );
    }
    tryLoad(_interstitialAdx);
  }

  Future<void> showInterstitial({void Function()? onClosed}) async {
    if (_interstitialAd == null) {
      onClosed?.call();
      return;
    }
    final closed = onClosed;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialLoaded = false;
        _lastInterstitialShownAt = DateTime.now();
        loadInterstitial();
        closed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialLoaded = false;
        loadInterstitial();
        closed?.call();
      },
    );
    await _interstitialAd!.show();
  }

  // --- Rewarded: ADX then AdMob ---
  void loadRewarded({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (!_config.rewardedAdsEnabled) {
      onFailed?.call();
      return;
    }
    void tryLoad(String adUnitId, {bool isAdmob = false}) {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedLoaded = true;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _rewardedAd = null;
                _rewardedLoaded = false;
                loadRewarded();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _rewardedAd = null;
                _rewardedLoaded = false;
                loadRewarded();
              },
            );
            onLoaded?.call();
          },
          onAdFailedToLoad: (error) {
            if (isAdmob) {
              onFailed?.call();
            } else {
              tryLoad(_rewardedAdmob, isAdmob: true);
            }
          },
        ),
      );
    }
    tryLoad(_rewardedAdx);
  }

  Future<void> showRewarded({
    required void Function() onReward,
    void Function(String)? onFailed,
  }) async {
    if (_rewardedAd == null) {
      onFailed?.call('Ad not ready');
      return;
    }
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onReward(),
    );
  }

  // --- App Open: ADX then AdMob ---
  void loadAppOpen({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (!_config.appOpenAdsEnabled) {
      onFailed?.call();
      return;
    }
    void tryLoad(String adUnitId, {bool isAdmob = false}) {
      AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _appOpenLoaded = true;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _appOpenAd = null;
                _appOpenLoaded = false;
                loadAppOpen();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _appOpenAd = null;
                _appOpenLoaded = false;
                loadAppOpen();
              },
            );
            onLoaded?.call();
          },
          onAdFailedToLoad: (error) {
            if (isAdmob) {
              onFailed?.call();
            } else {
              tryLoad(_appOpenAdmob, isAdmob: true);
            }
          },
        ),
      );
    }
    tryLoad(_appOpenAdx);
  }

  Future<void> showAppOpen({void Function()? onClosed}) async {
    if (_appOpenAd == null) {
      onClosed?.call();
      return;
    }
    _lastAppOpenShownAt = DateTime.now();
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoaded = false;
        loadAppOpen();
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoaded = false;
        loadAppOpen();
        onClosed?.call();
      },
    );
    await _appOpenAd!.show();
  }

  /// Interstitial: show with probability and min interval (from Remote Config). Non-blocking.
  Future<void> tryShowInterstitialRandomly() async {
    if (!_config.interstitialAdsEnabled) return;
    if (!isInterstitialReady) return;
    final now = DateTime.now();
    final intervalSec = _config.interstitialMinIntervalSeconds;
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!).inSeconds < intervalSec) return;
    final chance = _config.interstitialChancePercent;
    if (chance <= 0 || Random().nextInt(100) >= chance) return;
    await showInterstitial();
  }
}
