import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Controls ads and feature flags via Firebase Remote Config.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();
  FirebaseRemoteConfig get _config => FirebaseRemoteConfig.instance;

  static const String _keyRewardedAdsEnabled = 'rewarded_ads_enabled';
  static const String _keyInterstitialAdsEnabled = 'interstitial_ads_enabled';
  static const String _keyRewardedAdUnitIdAndroid = 'rewarded_ad_unit_id_android';
  static const String _keyRewardedAdUnitIdIos = 'rewarded_ad_unit_id_ios';
  static const String _keyInterstitialAdUnitIdAndroid = 'interstitial_ad_unit_id_android';
  static const String _keyInterstitialAdUnitIdIos = 'interstitial_ad_unit_id_ios';
  static const String _keyBoostMultiplierFromRewarded = 'boost_multiplier_rewarded';
  static const String _keyBoostDurationMinutes = 'boost_duration_minutes';
  static const String _keyBannerAdsEnabled = 'banner_ads_enabled';
  static const String _keyNativeAdsEnabled = 'native_ads_enabled';
  static const String _keyBannerAdUnitIdAndroid = 'banner_ad_unit_id_android';
  static const String _keyBannerAdUnitIdIos = 'banner_ad_unit_id_ios';
  static const String _keyNativeAdUnitIdAndroid = 'native_ad_unit_id_android';
  static const String _keyNativeAdUnitIdIos = 'native_ad_unit_id_ios';
  static const String _keyInterstitialChancePercent = 'interstitial_chance_percent';
  static const String _keyInterstitialMinIntervalSeconds = 'interstitial_min_interval_seconds';

  // Smart Mediation: ADX (first) + AdMob (fallback). All IDs from Firebase.
  static const String _keyBannerAdxAndroid = 'banner_adx_android';
  static const String _keyBannerAdxIos = 'banner_adx_ios';
  static const String _keyBannerAdmobAndroid = 'banner_admob_android';
  static const String _keyBannerAdmobIos = 'banner_admob_ios';
  static const String _keyNativeAdxAndroid = 'native_adx_android';
  static const String _keyNativeAdxIos = 'native_adx_ios';
  static const String _keyNativeAdmobAndroid = 'native_admob_android';
  static const String _keyNativeAdmobIos = 'native_admob_ios';
  static const String _keyInterstitialAdxAndroid = 'interstitial_adx_android';
  static const String _keyInterstitialAdxIos = 'interstitial_adx_ios';
  static const String _keyInterstitialAdmobAndroid = 'interstitial_admob_android';
  static const String _keyInterstitialAdmobIos = 'interstitial_admob_ios';
  static const String _keyRewardedAdxAndroid = 'rewarded_adx_android';
  static const String _keyRewardedAdxIos = 'rewarded_adx_ios';
  static const String _keyRewardedAdmobAndroid = 'rewarded_admob_android';
  static const String _keyRewardedAdmobIos = 'rewarded_admob_ios';
  static const String _keyAppOpenAdxAndroid = 'app_open_adx_android';
  static const String _keyAppOpenAdxIos = 'app_open_adx_ios';
  static const String _keyAppOpenAdmobAndroid = 'app_open_admob_android';
  static const String _keyAppOpenAdmobIos = 'app_open_admob_ios';
  static const String _keyAppOpenAdsEnabled = 'app_open_ads_enabled';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _config.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 5),
    ));
    await _config.setDefaults({
      _keyRewardedAdsEnabled: true,
      _keyInterstitialAdsEnabled: true,
      _keyRewardedAdUnitIdAndroid: 'ca-app-pub-3940256099942544/5224354917',
      _keyRewardedAdUnitIdIos: 'ca-app-pub-3940256099942544/1712485313',
      _keyInterstitialAdUnitIdAndroid: 'ca-app-pub-3940256099942544/1033173712',
      _keyInterstitialAdUnitIdIos: 'ca-app-pub-3940256099942544/4411468910',
      _keyBoostMultiplierFromRewarded: 2.0,
      _keyBoostDurationMinutes: 30,
      _keyBannerAdsEnabled: true,
      _keyNativeAdsEnabled: true,
      _keyBannerAdUnitIdAndroid: 'ca-app-pub-3940256099942544/6300978111',
      _keyBannerAdUnitIdIos: 'ca-app-pub-3940256099942544/2934735716',
      _keyNativeAdUnitIdAndroid: 'ca-app-pub-3940256099942544/2247696110',
      _keyNativeAdUnitIdIos: 'ca-app-pub-3940256099942544/3986624511',
      _keyInterstitialChancePercent: 28,
      _keyInterstitialMinIntervalSeconds: 55,
      _keyBannerAdxAndroid: 'ca-app-pub-3940256099942544/6300978111',
      _keyBannerAdxIos: 'ca-app-pub-3940256099942544/2934735716',
      _keyBannerAdmobAndroid: 'ca-app-pub-3940256099942544/6300978111',
      _keyBannerAdmobIos: 'ca-app-pub-3940256099942544/2934735716',
      _keyNativeAdxAndroid: 'ca-app-pub-3940256099942544/2247696110',
      _keyNativeAdxIos: 'ca-app-pub-3940256099942544/3986624511',
      _keyNativeAdmobAndroid: 'ca-app-pub-3940256099942544/2247696110',
      _keyNativeAdmobIos: 'ca-app-pub-3940256099942544/3986624511',
      _keyInterstitialAdxAndroid: 'ca-app-pub-3940256099942544/1033173712',
      _keyInterstitialAdxIos: 'ca-app-pub-3940256099942544/4411468910',
      _keyInterstitialAdmobAndroid: 'ca-app-pub-3940256099942544/1033173712',
      _keyInterstitialAdmobIos: 'ca-app-pub-3940256099942544/4411468910',
      _keyRewardedAdxAndroid: 'ca-app-pub-3940256099942544/5224354917',
      _keyRewardedAdxIos: 'ca-app-pub-3940256099942544/1712485313',
      _keyRewardedAdmobAndroid: 'ca-app-pub-3940256099942544/5224354917',
      _keyRewardedAdmobIos: 'ca-app-pub-3940256099942544/1712485313',
      _keyAppOpenAdxAndroid: 'ca-app-pub-3940256099942544/9257395921',
      _keyAppOpenAdxIos: 'ca-app-pub-3940256099942544/5575463023',
      _keyAppOpenAdmobAndroid: 'ca-app-pub-3940256099942544/9257395921',
      _keyAppOpenAdmobIos: 'ca-app-pub-3940256099942544/5575463023',
      _keyAppOpenAdsEnabled: true,
    });
    await _config.fetchAndActivate();
    _initialized = true;
  }

  bool get rewardedAdsEnabled => _config.getBool(_keyRewardedAdsEnabled);
  bool get interstitialAdsEnabled => _config.getBool(_keyInterstitialAdsEnabled);

  String get rewardedAdUnitId {
    // Use platform in real app; for Flutter default to Android test ID
    return _config.getString(_keyRewardedAdUnitIdAndroid);
  }

  String get rewardedAdUnitIdIos => _config.getString(_keyRewardedAdUnitIdIos);
  String get interstitialAdUnitId => _config.getString(_keyInterstitialAdUnitIdAndroid);
  String get interstitialAdUnitIdIos => _config.getString(_keyInterstitialAdUnitIdIos);

  double get boostMultiplierFromRewarded =>
      _config.getDouble(_keyBoostMultiplierFromRewarded);
  int get boostDurationMinutes => _config.getInt(_keyBoostDurationMinutes);

  bool get bannerAdsEnabled => _config.getBool(_keyBannerAdsEnabled);
  bool get nativeAdsEnabled => _config.getBool(_keyNativeAdsEnabled);
  String get bannerAdUnitIdAndroid => _config.getString(_keyBannerAdUnitIdAndroid);
  String get bannerAdUnitIdIos => _config.getString(_keyBannerAdUnitIdIos);
  String get nativeAdUnitIdAndroid => _config.getString(_keyNativeAdUnitIdAndroid);
  String get nativeAdUnitIdIos => _config.getString(_keyNativeAdUnitIdIos);

  /// Chance (0-100) to show interstitial on action/screen change. From Firebase.
  int get interstitialChancePercent => _config.getInt(_keyInterstitialChancePercent).clamp(0, 100);

  /// Min seconds between two interstitials. From Firebase.
  int get interstitialMinIntervalSeconds => _config.getInt(_keyInterstitialMinIntervalSeconds).clamp(15, 300);

  // --- Smart Mediation: ADX (first) + AdMob (fallback) IDs from Firebase ---
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
  bool get appOpenAdsEnabled => _config.getBool(_keyAppOpenAdsEnabled);
}
