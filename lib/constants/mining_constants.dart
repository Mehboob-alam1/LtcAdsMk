/// Mining limits and rates for Ethereum. Withdrawal at ~\$100 worth of ETH;
/// mining rate set so user needs ≥1 month (with all boosts) to reach \$100.
class MiningConstants {
  MiningConstants._();

  /// Withdrawal threshold in USD. User must have mined at least this much worth of ETH.
  static const double withdrawThresholdUsd = 100.0;

  /// Reference ETH price (USD) used for monthly cap. ~\$100/month max = this much ETH.
  /// Cap in ETH = withdrawThresholdUsd / referenceEthPriceUsd.
  static const double referenceEthPriceUsd = 3000.0;

  /// Maximum ETH a user can earn from mining in one month (all boosts apply to this cap).
  /// Set so at reference price the value is withdrawThresholdUsd (~\$100).
  static double get maxEthPerMonth => withdrawThresholdUsd / referenceEthPriceUsd;

  /// Minimum ETH required to request withdrawal (at reference price ≈ \$100).
  /// Actual check at withdraw time: balance * ethPriceUsd >= withdrawThresholdUsd.
  static double get minWithdrawEthAtReference => withdrawThresholdUsd / referenceEthPriceUsd;

  /// Seconds in 30 days (used for cap and base rate).
  static const int secondsPerMonth = 30 * 24 * 3600;

  /// Base mining rate per second (no boost). At 1x user gets half of monthly cap;
  /// with 2x boost they can reach cap. So with all boosts user needs ≥1 month for \$100.
  static double get baseEarningsPerSecond =>
      (maxEthPerMonth / 2) / secondsPerMonth;

  /// Format ETH with full decimals (up to 8 decimal places).
  static String formatEthFull(double eth) {
    if (eth == 0) return '0.00000000';
    return eth.toStringAsFixed(8);
  }

  /// Daily login bonus amount (ETH) per claim.
  static const double dailyLoginBonusEth = 0.00002;

  /// Referral bonus (ETH) for referrer when someone signs up with their code.
  static const double referralBonusEth = 0.0001;

  /// Default app share URL (Play Store).
  static const String appShareUrl =
      'https://play.google.com/store/apps/details?id=com.ethgiga.earn.cloudmining.ethmining.giga';

  /// Format very small ETH (e.g. rate per second).
  static String formatEthRate(double ethPerSec) {
    if (ethPerSec == 0) return '0.00000000';
    if (ethPerSec >= 0.00001) return ethPerSec.toStringAsFixed(8);
    return ethPerSec.toStringAsExponential(2);
  }

  // Legacy names for compatibility where DB/API still use "btc" key
  static double get maxBtcPerMonth => maxEthPerMonth;
  static String formatBtcFull(double v) => formatEthFull(v);
  static String formatBtcRate(double v) => formatEthRate(v);
  static double get dailyLoginBonusBtc => dailyLoginBonusEth;
  static double get referralBonusBtc => referralBonusEth;
  /// For display only; actual withdraw check uses balance * ethPrice >= withdrawThresholdUsd.
  static double get minWithdrawBtc => minWithdrawEthAtReference;
}
