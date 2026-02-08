/// Mining limits and rates. Kept realistic so monthly value stays under ~\$100.
class MiningConstants {
  MiningConstants._();

  /// Maximum BTC a user can earn from mining in one month (all boosts apply to this cap).
  /// ~0.001 BTC ≈ \$100 at \$100k/BTC so user does not exceed \$100/month value.
  static const double maxBtcPerMonth = 0.001;

  /// Minimum BTC required to request a withdrawal.
  static const double minWithdrawBtc = 0.000015;

  /// Seconds in 30 days (used for cap and base rate).
  static const int secondsPerMonth = 30 * 24 * 3600;

  /// Base mining rate per second (no boost). At 1x user gets half of monthly cap;
  /// with 2x boost they can reach cap. Kept low for a realistic feel.
  static const double baseEarningsPerSecond =
      (maxBtcPerMonth / 2) / secondsPerMonth;

  /// Format BTC with full decimals (up to 8 decimal places, no trailing zero trim).
  static String formatBtcFull(double btc) {
    if (btc == 0) return '0.00000000';
    final s = btc.toStringAsFixed(8);
    return s;
  }

  /// Daily login bonus amount (BTC) per claim.
  static const double dailyLoginBonusBtc = 0.00002;

  /// Referral bonus (BTC) for referrer when someone signs up with their code.
  static const double referralBonusBtc = 0.0001;

  /// Default app share URL (Play Store). Override via Remote Config if needed.
  static const String appShareUrl = 'https://play.google.com/store/apps/details?id=com.btcgiga.earn.cloudmining.btcmining.giga';

  /// Format very small BTC (e.g. rate per second) with more decimals.
  static String formatBtcRate(double btcPerSec) {
    if (btcPerSec == 0) return '0.00000000';
    if (btcPerSec >= 0.00001) return btcPerSec.toStringAsFixed(8);
    return btcPerSec.toStringAsExponential(2);
  }
}
