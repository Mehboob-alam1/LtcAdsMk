class UserStats {
  const UserStats({
    required this.balanceBtc,
    required this.hashrate,
    required this.activeRigs,
    required this.dailyEarnings,
    required this.sessionUptime,
    required this.rigEfficiency,
    required this.rewardStreak,
    this.lastSyncAt,
    this.lastDailyClaimAt,
    this.earnedThisMonth = 0.0,
    this.monthKey = '',
    this.rigBonusPercent = 0.0,
  });

  final double balanceBtc;
  final String hashrate;
  final int activeRigs;
  final String dailyEarnings;
  final String sessionUptime;
  final int rigEfficiency;
  final int rewardStreak;
  final int? lastSyncAt;
  /// Timestamp (ms) of last daily login claim. Used to allow one claim per calendar day.
  final int? lastDailyClaimAt;
  /// ETH earned in the current month (capped at MiningConstants.maxEthPerMonth).
  final double earnedThisMonth;
  /// e.g. "2025-02" for monthly cap reset.
  final String monthKey;
  /// Permanent mining rate bonus % from unlocked rigs in shop (e.g. 10, 20, 65).
  final double rigBonusPercent;

  factory UserStats.initial() {
    return const UserStats(
      balanceBtc: 0.0,
      hashrate: '0 TH/s',
      activeRigs: 0,
      dailyEarnings: '+0.00000 ETH',
      sessionUptime: '00:00:00',
      rigEfficiency: 0,
      rewardStreak: 0,
      lastSyncAt: null,
      lastDailyClaimAt: null,
      earnedThisMonth: 0.0,
      monthKey: '',
      rigBonusPercent: 0.0,
    );
  }

  factory UserStats.fromMap(Map data) {
    final balance = data['balanceBtc'];
    final active = data['activeRigs'];
    final efficiency = data['rigEfficiency'];
    final lastSync = data['lastSyncAt'];
    final lastDaily = data['lastDailyClaimAt'];
    final earned = data['earnedThisMonth'];
    final month = data['monthKey'];
    final rigBonus = data['rigBonusPercent'];
    return UserStats(
      balanceBtc: (balance is num) ? balance.toDouble() : 0.0,
      hashrate: (data['hashrate'] ?? '0 TH/s').toString(),
      activeRigs: (active is num) ? active.toInt() : 0,
      dailyEarnings: (data['dailyEarnings'] ?? '+0.00000 ETH').toString(),
      sessionUptime: (data['sessionUptime'] ?? '00:00:00').toString(),
      rigEfficiency: (efficiency is num) ? efficiency.toInt() : 0,
      rewardStreak: (data['rewardStreak'] is num)
          ? (data['rewardStreak'] as num).toInt()
          : 0,
      lastSyncAt: lastSync is num ? lastSync.toInt() : null,
      lastDailyClaimAt: lastDaily is num ? lastDaily.toInt() : null,
      earnedThisMonth: (earned is num) ? earned.toDouble() : 0.0,
      monthKey: (month ?? '').toString(),
      rigBonusPercent: (rigBonus is num) ? rigBonus.toDouble() : 0.0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'balanceBtc': balanceBtc,
      'hashrate': hashrate,
      'activeRigs': activeRigs,
      'dailyEarnings': dailyEarnings,
      'sessionUptime': sessionUptime,
      'rigEfficiency': rigEfficiency,
      'rewardStreak': rewardStreak,
      'lastSyncAt': lastSyncAt,
      'lastDailyClaimAt': lastDailyClaimAt,
      'earnedThisMonth': earnedThisMonth,
      'monthKey': monthKey,
      'rigBonusPercent': rigBonusPercent,
    };
  }
}
