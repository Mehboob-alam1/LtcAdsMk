/// Mining limits and rates for Litecoin. Withdrawal at ~\$100 worth of LTC;
/// mining rate set so user needs ≥1 month (with all boosts) to reach \$100.
class MiningConstants {
  MiningConstants._();

  /// Withdrawal threshold in USD. User must have mined at least this much worth of LTC.
  static const double withdrawThresholdUsd = 100.0;

  /// When true, minimum balance for withdrawal is ~\$0.01 for dev testing. Production and all test cases use \$100.
  static const bool withdrawTestMode = false;

  /// Effective minimum withdrawal in USD (lower in test mode).
  static double get effectiveWithdrawThresholdUsd =>
      withdrawTestMode ? 0.01 : withdrawThresholdUsd;

  /// Reference LTC price (USD) used for monthly cap. ~\$100/month max = this much LTC.
  static const double referenceLtcPriceUsd = 90.0;

  /// Maximum LTC a user can earn from mining in one month (all boosts apply to this cap).
  static double get maxLtcPerMonth => withdrawThresholdUsd / referenceLtcPriceUsd;

  /// Minimum LTC required to request withdrawal (at reference price ≈ \$100).
  static double get minWithdrawLtcAtReference => withdrawThresholdUsd / referenceLtcPriceUsd;

  /// Seconds in 30 days (used for cap and base rate).
  static const int secondsPerMonth = 30 * 24 * 3600;

  /// Base mining rate per second (no boost). At 1x user gets half of monthly cap;
  /// with 2x boost they can reach cap. So with all perks user needs ≥1 month for \$100.
  static double get baseEarningsPerSecond =>
      (maxLtcPerMonth / 2) / secondsPerMonth;

  /// Format LTC with full decimals (up to 8 decimal places).
  static String formatLtcFull(double ltc) {
    if (ltc == 0) return '0.00000000';
    return ltc.toStringAsFixed(8);
  }

  /// Daily login bonus amount (LTC) per claim.
  static const double dailyLoginBonusLtc = 0.0002;

  /// Referral bonus (LTC) for referrer when someone signs up with their code.
  static const double referralBonusLtc = 0.001;

  /// Default app share URL (Play Store).
  static const String appShareUrl =
      'https://play.google.com/store/apps/details?id=com.ltcgiga.earn.cloudmining.ltcmining.giga';

  /// Format very small LTC (e.g. rate per second).
  static String formatLtcRate(double ltcPerSec) {
    if (ltcPerSec == 0) return '0.00000000';
    if (ltcPerSec >= 0.00001) return ltcPerSec.toStringAsFixed(8);
    return ltcPerSec.toStringAsExponential(2);
  }

  // Legacy/DB compatibility: API still uses "btc" key for balance
  static double get maxBtcPerMonth => maxLtcPerMonth;
  static double get maxEthPerMonth => maxLtcPerMonth;
  static String formatBtcFull(double v) => formatLtcFull(v);
  static String formatKasFull(double v) => formatLtcFull(v);
  static String formatEthFull(double v) => formatLtcFull(v);
  static String formatBtcRate(double v) => formatLtcRate(v);
  static String formatEthRate(double v) => formatLtcRate(v);
  static double get dailyLoginBonusBtc => dailyLoginBonusLtc;
  static double get dailyLoginBonusEth => dailyLoginBonusLtc;
  static double get referralBonusBtc => referralBonusLtc;
  static double get referralBonusEth => referralBonusLtc;
  static double get minWithdrawBtc => minWithdrawLtcAtReference;
  static double get minWithdrawEthAtReference => minWithdrawLtcAtReference;
}
