import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'remote_config_service.dart';

/// Central ad mediation: load from BOTH AdMob and AdX (Ad Manager) for each slot;
/// whichever loads first is shown. Telemetry reports which network filled.
/// All unit IDs from Firebase Remote Config.
class SmartAdManager {
  SmartAdManager._();

  static final SmartAdManager instance = SmartAdManager._();

  final RemoteConfigService _config = RemoteConfigService.instance;

  bool _sdkInitialized = false;

  // App Open: single cached ad (winner of race)
  AppOpenAd? _appOpenAd;
  bool _appOpenLoaded = false;
  DateTime? _lastAppOpenShownAt;

  // Interstitial: dynamic so we can hold InterstitialAd or AdManagerInterstitialAd
  dynamic _interstitialAd;
  bool _interstitialLoaded = false;
  DateTime? _lastInterstitialShownAt;

  // Rewarded
  RewardedAd? _rewardedAd;
  bool _rewardedLoaded = false;

  // Native
  NativeAd? _nativeAd;
  bool _nativeLoaded = false;

  bool get isSdkInitialized => _sdkInitialized;
  bool get isInterstitialReady => _interstitialLoaded && _interstitialAd != null;
  bool get isRewardedReady => _rewardedLoaded && _rewardedAd != null;
  bool get isAppOpenReady => _appOpenLoaded && _appOpenAd != null;
  bool get isNativeReady => _nativeLoaded && _nativeAd != null;
  DateTime? get lastInterstitialShownAt => _lastInterstitialShownAt;
  DateTime? get lastAppOpenShownAt => _lastAppOpenShownAt;

  /// Optional: log which network loaded for each slot (e.g. "admob" or "adx").
  void Function(String slot, String network, {String? adUnitId})? onAdLoaded;

  static Future<void> initialize() async {
    if (instance._sdkInitialized) return;
    await MobileAds.instance.initialize();
    instance._sdkInitialized = true;
  }

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;

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

  // --- Banner: load both AdMob and AdX, use first that loads; dispose loser ---
  void loadBanner({
    required AdSize size,
    required void Function(AdWithView?) onResult,
  }) {
    if (kIsWeb || !_config.bannerAdsEnabled) {
      onResult(null);
      return;
    }
    var decided = false;
    var failed = 0;
    void win(dynamic ad, String network, String adUnitId) {
      if (decided) {
        _disposeBanner(ad);
        return;
      }
      decided = true;
      onAdLoaded?.call('banner', network, adUnitId: adUnitId);
      onResult(ad);
    }
    void onFail() {
      failed++;
      if (failed == 2 && !decided) {
        decided = true;
        onResult(null);
      }
    }

    // AdMob banner
    final bannerAdmob = BannerAd(
      adUnitId: _bannerAdmob,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => win(ad, 'admob', ad.adUnitId),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFail();
        },
      ),
    );
    bannerAdmob.load();

    // AdX/Ad Manager banner (race in parallel)
    final adx = AdManagerBannerAd(
      adUnitId: _bannerAdx,
      sizes: [size],
      request: const AdManagerAdRequest(),
      listener: AdManagerBannerAdListener(
        onAdLoaded: (ad) {
          if (decided) {
            ad.dispose();
            return;
          }
          decided = true;
          win(ad, 'adx', ad.adUnitId);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFail();
        },
      ),
    );
    adx.load();
  }

  void _disposeBanner(dynamic ad) {
    try {
      ad.dispose();
    } catch (_) {}
  }

  // --- Native: load both, use first that loads. Returns cached ad if already loaded. ---
  void loadNative({
    NativeTemplateStyle? nativeTemplateStyle,
    void Function(NativeAd?)? onResult,
  }) {
    if (kIsWeb || !_config.nativeAdsEnabled) {
      onResult?.call(null);
      return;
    }
    if (_nativeLoaded && _nativeAd != null) {
      onResult?.call(_nativeAd);
      return;
    }
    final style = nativeTemplateStyle ?? NativeTemplateStyle(templateType: TemplateType.small);
    var decided = false;
    void win(NativeAd ad, String network) {
      if (decided) {
        ad.dispose();
        return;
      }
      decided = true;
      _nativeAd?.dispose();
      _nativeAd = ad;
      _nativeLoaded = true;
      onAdLoaded?.call('native', network, adUnitId: ad.adUnitId);
      onResult?.call(ad);
    }

    Future<NativeAd> loadAdmob() {
      final c = Completer<NativeAd>();
      final ad = NativeAd(
        adUnitId: _nativeAdmob,
        request: const AdRequest(),
        nativeTemplateStyle: style,
        listener: NativeAdListener(
          onAdLoaded: (a) {
            if (!c.isCompleted) c.complete(a as NativeAd);
          },
          onAdFailedToLoad: (a, e) {
            a.dispose();
            if (!c.isCompleted) c.completeError(e);
          },
        ),
      );
      ad.load();
      return c.future.timeout(const Duration(seconds: 10), onTimeout: () {
        ad.dispose();
        throw TimeoutException('Native AdMob');
      });
    }

    Future<NativeAd> loadAdx() {
      final c = Completer<NativeAd>();
      final ad = NativeAd(
        adUnitId: _nativeAdx,
        request: const AdRequest(),
        nativeTemplateStyle: style,
        listener: NativeAdListener(
          onAdLoaded: (a) {
            if (!c.isCompleted) c.complete(a as NativeAd);
          },
          onAdFailedToLoad: (a, e) {
            a.dispose();
            if (!c.isCompleted) c.completeError(e);
          },
        ),
      );
      ad.load();
      return c.future.timeout(const Duration(seconds: 10), onTimeout: () {
        ad.dispose();
        throw TimeoutException('Native AdX');
      });
    }

    var failed = 0;
    void onFail() {
      failed++;
      if (failed == 2 && !decided) {
        decided = true;
        onResult?.call(null);
      }
    }
    final f1 = loadAdmob();
    final f2 = loadAdx();
    f1.then((ad) {
      if (!decided) {
        decided = true;
        win(ad, 'admob');
      } else {
        ad.dispose();
      }
    }).catchError((_) => onFail());
    f2.then((ad) {
      if (!decided) {
        decided = true;
        win(ad, 'adx');
      } else {
        ad.dispose();
      }
    }).catchError((_) => onFail());
  }

  NativeAd? get currentNativeAd => _nativeLoaded ? _nativeAd : null;

  // --- App Open: load both, cache first; dispose loser when it loads ---
  void loadAppOpen({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (kIsWeb || !_config.appOpenAdsEnabled) {
      onFailed?.call();
      return;
    }
    if (_appOpenLoaded && _appOpenAd != null) {
      onLoaded?.call();
      return;
    }

    AppOpenAd? winner;
    void setWinner(AppOpenAd ad, String network) {
      if (winner != null) {
        ad.dispose();
        return;
      }
      winner = ad;
      _appOpenAd?.dispose();
      _appOpenAd = ad;
      _appOpenLoaded = true;
      onAdLoaded?.call('app_open', network, adUnitId: ad.adUnitId);
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _appOpenAd = null;
          _appOpenLoaded = false;
          loadAppOpen();
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
          _appOpenAd = null;
          _appOpenLoaded = false;
          loadAppOpen();
        },
      );
      onLoaded?.call();
    }

    Future<AppOpenAd> loadAdmob() {
      final c = Completer<AppOpenAd>();
      AppOpenAd.load(
        adUnitId: _appOpenAdmob,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (!c.isCompleted) c.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!c.isCompleted) c.completeError(error);
          },
        ),
      );
      return c.future.timeout(const Duration(seconds: 8), onTimeout: () {
        throw TimeoutException('AppOpen AdMob');
      });
    }

    Future<AppOpenAd> loadAdx() {
      final c = Completer<AppOpenAd>();
      AppOpenAd.loadWithAdManagerAdRequest(
        adUnitId: _appOpenAdx,
        adManagerAdRequest: const AdManagerAdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (!c.isCompleted) c.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!c.isCompleted) c.completeError(error);
          },
        ),
      );
      return c.future.timeout(const Duration(seconds: 8), onTimeout: () {
        throw TimeoutException('AppOpen AdX');
      });
    }

    final fAdmob = loadAdmob();
    final fAdx = loadAdx();
    Future.any([fAdmob, fAdx]).then((ad) {
      final network = ad.adUnitId == _appOpenAdmob ? 'admob' : 'adx';
      setWinner(ad, network);
    }).catchError((_) {
      onFailed?.call();
    });
    fAdmob.then((ad) {
      if (winner != null && winner != ad) ad.dispose();
    }).catchError((_) {});
    fAdx.then((ad) {
      if (winner != null && winner != ad) ad.dispose();
    }).catchError((_) {});
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

  // --- Interstitial: load both, show first that loads ---
  void loadInterstitial({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (kIsWeb || !_config.interstitialAdsEnabled) {
      onFailed?.call();
      return;
    }

    dynamic winner;
    void setWinner(dynamic ad, String network) {
      if (winner != null) {
        try {
          ad.dispose();
        } catch (_) {}
        return;
      }
      winner = ad;
      _interstitialAd?.dispose();
      _interstitialAd = ad;
      _interstitialLoaded = true;
      final unitId = (ad is InterstitialAd) ? ad.adUnitId : (ad as AdManagerInterstitialAd).adUnitId;
      onAdLoaded?.call('interstitial', network, adUnitId: unitId);
      onLoaded?.call();
    }

    Future<InterstitialAd> loadAdmob() {
      final c = Completer<InterstitialAd>();
      InterstitialAd.load(
        adUnitId: _interstitialAdmob,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!c.isCompleted) c.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!c.isCompleted) c.completeError(error);
          },
        ),
      );
      return c.future.timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Interstitial AdMob');
      });
    }

    Future<AdManagerInterstitialAd> loadAdx() {
      final c = Completer<AdManagerInterstitialAd>();
      AdManagerInterstitialAd.load(
        adUnitId: _interstitialAdx,
        request: const AdManagerAdRequest(),
        adLoadCallback: AdManagerInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (!c.isCompleted) c.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!c.isCompleted) c.completeError(error);
          },
        ),
      );
      return c.future.timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Interstitial AdX');
      });
    }

    final fAdmob = loadAdmob();
    final fAdx = loadAdx();
    Future.any<dynamic>([fAdmob, fAdx]).then((ad) {
      final network = (ad is InterstitialAd && ad.adUnitId == _interstitialAdmob) ? 'admob' : 'adx';
      setWinner(ad, network);
    }).catchError((_) {
      onFailed?.call();
    });
    fAdmob.then((ad) {
      if (winner != null && winner != ad) ad.dispose();
    }).catchError((_) {});
    fAdx.then((ad) {
      if (winner != null && winner != ad) ad.dispose();
    }).catchError((_) {});
  }

  Future<void> showInterstitial({void Function()? onClosed}) async {
    if (_interstitialAd == null) {
      onClosed?.call();
      return;
    }
    final ad = _interstitialAd;
    final closed = onClosed;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        (a as dynamic)?.dispose();
        _interstitialAd = null;
        _interstitialLoaded = false;
        loadInterstitial();
        closed?.call();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        (a as dynamic)?.dispose();
        _interstitialAd = null;
        _interstitialLoaded = false;
        loadInterstitial();
        closed?.call();
      },
    );
    await ad.show();
  }

  // --- Rewarded: load both, use first that loads ---
  void loadRewarded({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    if (kIsWeb || !_config.rewardedAdsEnabled) {
      onFailed?.call();
      return;
    }

    RewardedAd? winner;
    void setWinner(RewardedAd ad, String network) {
      if (winner != null) {
        ad.dispose();
        return;
      }
      winner = ad;
      _rewardedAd?.dispose();
      _rewardedAd = ad;
      _rewardedLoaded = true;
      onAdLoaded?.call('rewarded', network, adUnitId: ad.adUnitId);
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _rewardedAd = null;
          _rewardedLoaded = false;
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (a, error) {
          a.dispose();
          _rewardedAd = null;
          _rewardedLoaded = false;
          loadRewarded();
        },
      );
      onLoaded?.call();
    }

    Future<RewardedAd> loadAdmob() {
      final c = Completer<RewardedAd>();
      RewardedAd.load(
        adUnitId: _rewardedAdmob,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!c.isCompleted) c.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!c.isCompleted) c.completeError(error);
          },
        ),
      );
      return c.future.timeout(const Duration(seconds: 12), onTimeout: () {
        throw TimeoutException('Rewarded AdMob');
      });
    }

    Future<RewardedAd> loadAdx() {
      final c = Completer<RewardedAd>();
      RewardedAd.loadWithAdManagerAdRequest(
        adUnitId: _rewardedAdx,
        adManagerRequest: const AdManagerAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!c.isCompleted) c.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!c.isCompleted) c.completeError(error);
          },
        ),
      );
      return c.future.timeout(const Duration(seconds: 12), onTimeout: () {
        throw TimeoutException('Rewarded AdX');
      });
    }

    final fAdmob = loadAdmob();
    final fAdx = loadAdx();
    Future.any([fAdmob, fAdx]).then((ad) {
      final network = ad.adUnitId == _rewardedAdmob ? 'admob' : 'adx';
      setWinner(ad, network);
    }).catchError((_) {
      onFailed?.call();
    });
    fAdmob.then((ad) {
      if (winner != null && winner != ad) ad.dispose();
    }).catchError((_) {});
    fAdx.then((ad) {
      if (winner != null && winner != ad) ad.dispose();
    }).catchError((_) {});
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
