import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Controls ads and feature flags via Firebase Remote Config.
/// Matches remote_config_parameters.json: ads_enabled, *_adx_android, *_admob_android, and numeric flags.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();
  FirebaseRemoteConfig get _config => FirebaseRemoteConfig.instance;

  /// Single switch: when false, all ads are off. Key in RC: ads_enabled
  static const String _keyAdsEnabled = 'ads_enabled';
  static const String _keyBoostMultiplierFromRewarded = 'boost_multiplier_rewarded';
  static const String _keyBoostDurationMinutes = 'boost_duration_minutes';
  static const String _keyInterstitialChancePercent = 'interstitial_chance_percent';
  static const String _keyInterstitialMinIntervalSeconds = 'interstitial_min_interval_seconds';

  // Ad unit IDs (Android only in RC for now). Key suffix: _adx_android, _admob_android
  static const String _keyBannerAdxAndroid = 'banner_adx_android';
  static const String _keyBannerAdmobAndroid = 'banner_admob_android';
  static const String _keyNativeAdxAndroid = 'native_adx_android';
  static const String _keyNativeAdmobAndroid = 'native_admob_android';
  static const String _keyInterstitialAdxAndroid = 'interstitial_adx_android';
  static const String _keyInterstitialAdmobAndroid = 'interstitial_admob_android';
  static const String _keyRewardedAdxAndroid = 'rewarded_adx_android';
  static const String _keyRewardedAdmobAndroid = 'rewarded_admob_android';
  static const String _keyAppOpenAdxAndroid = 'app_open_adx_android';
  static const String _keyAppOpenAdmobAndroid = 'app_open_admob_android';

  // iOS keys (optional; app defaults used if not in RC)
  static const String _keyBannerAdxIos = 'banner_adx_ios';
  static const String _keyBannerAdmobIos = 'banner_admob_ios';
  static const String _keyNativeAdxIos = 'native_adx_ios';
  static const String _keyNativeAdmobIos = 'native_admob_ios';
  static const String _keyInterstitialAdxIos = 'interstitial_adx_ios';
  static const String _keyInterstitialAdmobIos = 'interstitial_admob_ios';
  static const String _keyRewardedAdxIos = 'rewarded_adx_ios';
  static const String _keyRewardedAdmobIos = 'rewarded_admob_ios';
  static const String _keyAppOpenAdxIos = 'app_open_adx_ios';
  static const String _keyAppOpenAdmobIos = 'app_open_admob_ios';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _config.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 5),
    ));
    await _config.setDefaults({
      _keyAdsEnabled: true,
      _keyBoostMultiplierFromRewarded: 2.0,
      _keyBoostDurationMinutes: 30,
      _keyInterstitialChancePercent: 28,
      _keyInterstitialMinIntervalSeconds: 55,
      _keyBannerAdxAndroid: 'ca-app-pub-3940256099942544/6300978111',
      _keyBannerAdmobAndroid: 'ca-app-pub-3940256099942544/6300978111',
      _keyNativeAdxAndroid: 'ca-app-pub-3940256099942544/2247696110',
      _keyNativeAdmobAndroid: 'ca-app-pub-3940256099942544/2247696110',
      _keyInterstitialAdxAndroid: 'ca-app-pub-3940256099942544/1033173712',
      _keyInterstitialAdmobAndroid: 'ca-app-pub-3940256099942544/1033173712',
      _keyRewardedAdxAndroid: 'ca-app-pub-3940256099942544/5224354917',
      _keyRewardedAdmobAndroid: 'ca-app-pub-3940256099942544/5224354917',
      _keyAppOpenAdxAndroid: 'ca-app-pub-3940256099942544/9257395921',
      _keyAppOpenAdmobAndroid: 'ca-app-pub-3940256099942544/9257395921',
      _keyBannerAdxIos: 'ca-app-pub-3940256099942544/2934735716',
      _keyBannerAdmobIos: 'ca-app-pub-3940256099942544/2934735716',
      _keyNativeAdxIos: 'ca-app-pub-3940256099942544/3986624511',
      _keyNativeAdmobIos: 'ca-app-pub-3940256099942544/3986624511',
      _keyInterstitialAdxIos: 'ca-app-pub-3940256099942544/4411468910',
      _keyInterstitialAdmobIos: 'ca-app-pub-3940256099942544/4411468910',
      _keyRewardedAdxIos: 'ca-app-pub-3940256099942544/1712485313',
      _keyRewardedAdmobIos: 'ca-app-pub-3940256099942544/1712485313',
      _keyAppOpenAdxIos: 'ca-app-pub-3940256099942544/5575463023',
      _keyAppOpenAdmobIos: 'ca-app-pub-3940256099942544/5575463023',
    });
    await _config.fetchAndActivate();
    _initialized = true;
  }

  /// Master switch: when false, no ads are loaded or shown. RC key: ads_enabled
  bool get adsEnabled => _config.getBool(_keyAdsEnabled);

  bool get rewardedAdsEnabled => adsEnabled;
  bool get interstitialAdsEnabled => adsEnabled;
  bool get bannerAdsEnabled => adsEnabled;
  bool get nativeAdsEnabled => adsEnabled;
  bool get appOpenAdsEnabled => adsEnabled;

  String get rewardedAdUnitId => _config.getString(_keyRewardedAdmobAndroid);
  String get rewardedAdUnitIdIos => _config.getString(_keyRewardedAdmobIos);
  String get interstitialAdUnitId => _config.getString(_keyInterstitialAdmobAndroid);
  String get interstitialAdUnitIdIos => _config.getString(_keyInterstitialAdmobIos);
  String get bannerAdUnitIdAndroid => _config.getString(_keyBannerAdmobAndroid);
  String get bannerAdUnitIdIos => _config.getString(_keyBannerAdmobIos);
  String get nativeAdUnitIdAndroid => _config.getString(_keyNativeAdmobAndroid);
  String get nativeAdUnitIdIos => _config.getString(_keyNativeAdmobIos);

  double get boostMultiplierFromRewarded =>
      _config.getDouble(_keyBoostMultiplierFromRewarded);
  int get boostDurationMinutes => _config.getInt(_keyBoostDurationMinutes);

  int get interstitialChancePercent =>
      _config.getInt(_keyInterstitialChancePercent).clamp(0, 100);
  int get interstitialMinIntervalSeconds =>
      _config.getInt(_keyInterstitialMinIntervalSeconds).clamp(15, 300);

  String get bannerAdxAndroid => _config.getString(_keyBannerAdxAndroid);
  String get bannerAdxIos => _config.getString(_keyBannerAdxIos);
  String get bannerAdmobAndroid => _config.getString(_keyBannerAdmobAndroid);
  String get bannerAdmobIos => _config.getString(_keyBannerAdmobIos);
  String get nativeAdxAndroid => _config.getString(_keyNativeAdxAndroid);
  String get nativeAdxIos => _config.getString(_keyNativeAdxIos);
  String get nativeAdmobAndroid => _config.getString(_keyNativeAdmobAndroid);
  String get nativeAdmobIos => _config.getString(_keyNativeAdmobIos);
  String get interstitialAdxAndroid => _config.getString(_keyInterstitialAdxAndroid);
  String get interstitialAdxIos => _config.getString(_keyInterstitialAdxIos);
  String get interstitialAdmobAndroid => _config.getString(_keyInterstitialAdmobAndroid);
  String get interstitialAdmobIos => _config.getString(_keyInterstitialAdmobIos);
  String get rewardedAdxAndroid => _config.getString(_keyRewardedAdxAndroid);
  String get rewardedAdxIos => _config.getString(_keyRewardedAdxIos);
  String get rewardedAdmobAndroid => _config.getString(_keyRewardedAdmobAndroid);
  String get rewardedAdmobIos => _config.getString(_keyRewardedAdmobIos);
  String get appOpenAdxAndroid => _config.getString(_keyAppOpenAdxAndroid);
  String get appOpenAdxIos => _config.getString(_keyAppOpenAdxIos);
  String get appOpenAdmobAndroid => _config.getString(_keyAppOpenAdmobAndroid);
  String get appOpenAdmobIos => _config.getString(_keyAppOpenAdmobIos);
}
