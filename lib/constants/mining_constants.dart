/// Mining limits and rates for Kaspa. Withdrawal at ~\$100 worth of KAS;
/// mining rate set so user needs ≥1 month (with all boosts) to reach \$100.
class MiningConstants {
  MiningConstants._();

  /// Withdrawal threshold in USD. User must have mined at least this much worth of KAS.
  static const double withdrawThresholdUsd = 100.0;

  /// When true, minimum balance for withdrawal is ~\$0.01 for dev testing. Production and all test cases use \$100.
  static const bool withdrawTestMode = false;

  /// Effective minimum withdrawal in USD (lower in test mode).
  static double get effectiveWithdrawThresholdUsd =>
      withdrawTestMode ? 0.01 : withdrawThresholdUsd;

  /// Reference KAS price (USD) used for monthly cap. ~\$100/month max = this much KAS.
  static const double referenceKasPriceUsd = 0.10;

  /// Maximum KAS a user can earn from mining in one month (all boosts apply to this cap).
  static double get maxKasPerMonth => withdrawThresholdUsd / referenceKasPriceUsd;

  /// Minimum KAS required to request withdrawal (at reference price ≈ \$100).
  static double get minWithdrawKasAtReference => withdrawThresholdUsd / referenceKasPriceUsd;

  /// Seconds in 30 days (used for cap and base rate).
  static const int secondsPerMonth = 30 * 24 * 3600;

  /// Base mining rate per second (no boost). At 1x user gets half of monthly cap;
  /// with 2x boost they can reach cap. So with all perks user needs ≥1 month for \$100.
  static double get baseEarningsPerSecond =>
      (maxKasPerMonth / 2) / secondsPerMonth;

  /// Format KAS for display (up to 4 decimal places for readability).
  static String formatKasFull(double kas) {
    if (kas == 0) return '0.0000';
    if (kas >= 1000) return kas.toStringAsFixed(0);
    if (kas >= 1) return kas.toStringAsFixed(4);
    return kas.toStringAsFixed(4);
  }

  /// Daily login bonus amount (KAS) per claim.
  static const double dailyLoginBonusKas = 0.5;

  /// Referral bonus (KAS) for referrer when someone signs up with their code.
  static const double referralBonusKas = 2.0;

  /// Default app share URL (Play Store).
  static const String appShareUrl =
      'https://play.google.com/store/apps/details?id=com.kaspa.earn.cloudmining.kaspamining.giga';

  /// Format very small KAS (e.g. rate per second).
  static String formatKasRate(double kasPerSec) {
    if (kasPerSec == 0) return '0.0000';
    if (kasPerSec >= 0.0001) return kasPerSec.toStringAsFixed(6);
    return kasPerSec.toStringAsExponential(2);
  }

  // Legacy/DB compatibility: API still uses "btc" key for balance
  static double get maxBtcPerMonth => maxKasPerMonth;
  static double get maxEthPerMonth => maxKasPerMonth;
  static String formatBtcFull(double v) => formatKasFull(v);
  static String formatLtcFull(double v) => formatKasFull(v);
  static String formatEthFull(double v) => formatKasFull(v);
  static String formatBtcRate(double v) => formatKasRate(v);
  static String formatEthRate(double v) => formatKasRate(v);
  static double get dailyLoginBonusBtc => dailyLoginBonusKas;
  static double get dailyLoginBonusEth => dailyLoginBonusKas;
  static double get referralBonusBtc => referralBonusKas;
  static double get referralBonusEth => referralBonusKas;
  static double get minWithdrawBtc => minWithdrawKasAtReference;
  static double get minWithdrawEthAtReference => minWithdrawKasAtReference;
}
