import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../constants/mining_constants.dart';
import '../constants/shop_items.dart';
import '../models/user_stats.dart';
import '../models/transaction_item.dart';
import '../models/activity_item.dart';
import '../models/leaderboard_entry.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Base mining rate (BTC/sec). Max 0.000014 BTC/month with boosts; controlled by MiningConstants.
  static double get miningEarningsPerSecond => MiningConstants.baseEarningsPerSecond;

  DatabaseReference _userRef(String uid) => _db.ref('users/$uid');

  /// Broadcast streams so StreamBuilders can re-subscribe when widgets rebuild (e.g. after scroll).
  static final Map<String, Stream<UserStats>> _statsStreamCache = {};
  static final Map<String, Stream<Map<String, dynamic>>> _miningStreamCache = {};
  static final Map<String, Stream<Map<String, dynamic>>> _boostProgressStreamCache = {};
  static final Map<String, Stream<Map<String, dynamic>>> _shopProgressStreamCache = {};
  static final Map<String, Stream<List<ActivityItem>>> _activityStreamCache = {};
  static final Map<String, Stream<List<TransactionItem>>> _withdrawalsStreamCache = {};
  static final Map<String, Stream<List<TransactionItem>>> _boostsStreamCache = {};

  Stream<UserStats> statsStream(String uid) {
    return _statsStreamCache.putIfAbsent(uid, () {
      return _userRef(uid).child('stats').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          return UserStats.fromMap(data);
        }
        return UserStats.initial();
      }).asBroadcastStream();
    });
  }

  Future<void> ensureUserSeed(User user) async {
    final ref = _userRef(user.uid);
    final statsSnap = await ref.child('stats').get();
    if (!statsSnap.exists) {
      await ref.child('stats').set(UserStats.initial().toMap());
    }
    final profileSnap = await ref.child('profile').get();
    if (!profileSnap.exists) {
      final referralCode = await _generateUniqueReferralCode(user.uid);
      await ref.child('profile').set({
        'name': user.displayName ?? (user.isAnonymous ? 'Guest Miner' : 'Miner'),
        'tier': 'Platinum',
        'createdAt': ServerValue.timestamp,
        'referralCode': referralCode,
      });
      await _db.ref('referralCodes').child(referralCode).set(user.uid);
    } else {
      await _ensureReferralCode(ref, user.uid);
    }
    final miningSnap = await ref.child('mining').get();
    if (!miningSnap.exists) {
      await ref.child('mining').set({
        'active': false,
        'startedAt': null,
        'lastStartAt': null,
        'balanceAtStart': null,
        'boostMultiplier': 1.0,
        'boostEndsAt': null,
        'sessionEndsAt': null,
      });
    }
    final boostProgressSnap = await ref.child('boostProgress').get();
    if (!boostProgressSnap.exists) {
      await ref.child('boostProgress').set({
        'adsForDayBoost': 0,
      });
    }
    final shopSnap = await ref.child('shopProgress').get();
    if (!shopSnap.exists) {
      await ref.child('shopProgress').set({
        'adsForAutoMiningDay': 0,
        'autoMiningDayUnlocked': false,
        'usedAutoMiningDayAt': null,
        'adsForRig1': 0,
        'rig1Unlocked': false,
        'adsForRig2': 0,
        'rig2Unlocked': false,
        'adsForRig3': 0,
        'rig3Unlocked': false,
        'adsForMegaBoost': 0,
        'megaBoostUnlocked': false,
        'adsForDoubleSession': 0,
        'doubleSessionAvailable': false,
        'nextSessionHours': null,
        'luckySpinCount_rig1': 0,
        'luckySpinCount_rig2': 0,
        'luckySpinCount_rig3': 0,
        'luckySpinCount_megaBoost': 0,
        'luckySpinCount_autoMiningDay': 0,
        'luckySpinCount_doubleSession': 0,
      });
    }
  }

  static const _referralCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Generates a 6-char code from [seed] (deterministic: same seed => same code).
  String _generateReferralCodeFromSeed(String seed) {
    var h = seed.hashCode.abs();
    final code = List.generate(6, (_) {
      final i = h % _referralCodeChars.length;
      h = h ~/ _referralCodeChars.length;
      if (h == 0) h = seed.hashCode.abs();
      return _referralCodeChars[i];
    });
    return code.join();
  }

  /// Returns a referral code unique across all users (checks Firebase, retries on collision).
  Future<String> _generateUniqueReferralCode(String uid) async {
    for (var i = 0; i < 15; i++) {
      final seed = i == 0 ? uid : '${uid}_$i';
      final code = _generateReferralCodeFromSeed(seed);
      final existing = await _db.ref('referralCodes').child(code).get();
      final existingUid = existing.value?.toString();
      if (existingUid == null || existingUid == uid) return code;
    }
    return _generateReferralCodeFromSeed('${uid}_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> _ensureReferralCode(DatabaseReference userRef, String uid) async {
    final profileSnap = await userRef.child('profile').get();
    if (!profileSnap.exists) return;
    final data = profileSnap.value as Map<dynamic, dynamic>?;
    if (data?.containsKey('referralCode') != true) {
      final code = await _generateUniqueReferralCode(uid);
      await userRef.child('profile').update({'referralCode': code});
      await _db.ref('referralCodes').child(code).set(uid);
    }
  }

  /// Get or create referral code for user. Returns 6-char code.
  Future<String> getReferralCode(String uid) async {
    await _ensureReferralCode(_userRef(uid), uid);
    final snap = await _userRef(uid).child('profile').child('referralCode').get();
    return (snap.value ?? _generateReferralCodeFromSeed(uid)).toString();
  }

  /// Resolve referral code to referrer uid. Returns null if invalid.
  Future<String?> getUidByReferralCode(String code) async {
    if (code.isEmpty) return null;
    final clean = code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length < 4) return null;
    final snap = await _db.ref('referralCodes').child(clean).get();
    return snap.value?.toString();
  }

  /// Apply referral: credit referrer and set referredBy on referred user. Returns true if applied.
  Future<bool> recordReferral(String referralCode, String referredUid) async {
    final referrerUid = await getUidByReferralCode(referralCode);
    if (referrerUid == null || referrerUid == referredUid) return false;
    final ref = _userRef(referredUid).child('profile');
    final existing = await ref.child('referredBy').get();
    if (existing.exists) return false;
    await ref.update({'referredBy': referrerUid});
    final statsRef = _userRef(referrerUid).child('stats');
    final snap = await statsRef.child('balanceBtc').get();
    final current = (snap.value is num) ? (snap.value as num).toDouble() : 0.0;
    await statsRef.update({'balanceBtc': current + MiningConstants.referralBonusBtc});
    await _userRef(referrerUid).child('activity').push().set({
      'type': 'referral',
      'label': 'Referral bonus +${MiningConstants.referralBonusBtc} BTC',
      'createdAt': ServerValue.timestamp,
    });
    return true;
  }

  /// Increment Lucky Spin count for an item (for tracking). Key: luckySpinCount_<itemId>.
  Future<void> incrementLuckySpinCount(String uid, String itemId) async {
    final key = 'luckySpinCount_$itemId';
    final ref = _userRef(uid).child('shopProgress').child(key);
    final snap = await ref.get();
    final current = (snap.value is num) ? (snap.value as num).toInt() : 0;
    await ref.set(current + 1);
  }

  /// Session duration in hours. Default 4h; use 24 for auto-mining pack.
  static const int defaultSessionHours = 4;

  Future<void> startMining(String uid, {double balanceAtStart = 0.0, int sessionDurationHours = 4}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionEndsAt = now + sessionDurationHours * 3600 * 1000;
    final miningRef = _userRef(uid).child('mining');
    await miningRef.update({
      'active': true,
      'startedAt': ServerValue.timestamp,
      'lastStartAt': ServerValue.timestamp,
      'balanceAtStart': balanceAtStart,
      'sessionEndsAt': sessionEndsAt,
      'sessionDurationHours': sessionDurationHours,
    });
    await _userRef(uid).child('activity').push().set({
      'type': 'mining_start',
      'label': 'Start Mining ${sessionDurationHours}h',
      'createdAt': ServerValue.timestamp,
    });
  }

  /// Apply boost from rewarded ad. Stacks with current boost: new end = max(now, currentEnd) + duration.
  Future<void> applyBoost(String uid, {required double multiplier, required int durationMinutes}) async {
    final miningSnap = await _userRef(uid).child('mining').get();
    final data = miningSnap.value as Map<dynamic, dynamic>?;
    final currentEndsAt = data?['boostEndsAt'];
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentEnd = (currentEndsAt is num && currentEndsAt > now) ? currentEndsAt.toInt() : now;
    final endsAt = currentEnd + durationMinutes * 60 * 1000;
    await _userRef(uid).child('mining').update({
      'boostMultiplier': multiplier,
      'boostEndsAt': endsAt,
    });
    await _userRef(uid).child('activity').push().set({
      'type': 'boost',
      'label': '${multiplier}x for ${durationMinutes}min',
      'createdAt': ServerValue.timestamp,
    });
  }

  static const double _boostMultiplier = 2.0;

  Stream<Map<String, dynamic>> boostProgressStream(String uid) {
    return _boostProgressStreamCache.putIfAbsent(uid, () {
      return _userRef(uid).child('boostProgress').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return {'adsForDayBoost': 0};
      }).asBroadcastStream();
    });
  }

  /// Increment ads watched for day boost. Returns new count. If reaches 5, applies 1-day boost and resets to 0.
  Future<int> incrementDayBoostAds(String uid) async {
    final ref = _userRef(uid).child('boostProgress').child('adsForDayBoost');
    final snap = await ref.get();
    final current = (snap.value is num) ? (snap.value as num).toInt() : 0;
    final next = current + 1;
    if (next >= 5) {
      await ref.set(0);
      await applyBoost(uid, multiplier: _boostMultiplier, durationMinutes: 24 * 60);
      return 0;
    }
    await ref.set(next);
    return next;
  }

  /// Ferma il mining e opzionalmente persiste balance e uptime finali su Firebase.
  Future<void> stopMining(
    String uid, {
    double? finalBalanceBtc,
    String? finalSessionUptime,
  }) async {
    if (finalBalanceBtc != null || finalSessionUptime != null) {
      final updates = <String, Object?>{};
      if (finalBalanceBtc != null) updates['balanceBtc'] = finalBalanceBtc;
      if (finalSessionUptime != null) {
        updates['sessionUptime'] = finalSessionUptime;
      }
      updates['lastSyncAt'] = ServerValue.timestamp;
      await _userRef(uid).child('stats').update(updates);
    }
    final miningRef = _userRef(uid).child('mining');
    await miningRef.update({
      'active': false,
      'stoppedAt': ServerValue.timestamp,
      'balanceAtStart': null,
      'sessionEndsAt': null,
    });
    await _userRef(uid).child('activity').push().set({
      'type': 'mining_stop',
      'label': 'Stop Mining',
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<Map<String, dynamic>> miningStream(String uid) {
    return _miningStreamCache.putIfAbsent(uid, () {
      return _userRef(uid).child('mining').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return {'active': false, 'startedAt': null, 'sessionEndsAt': null};
      }).asBroadcastStream();
    });
  }

  Stream<Map<String, dynamic>> shopProgressStream(String uid) {
    return _shopProgressStreamCache.putIfAbsent(uid, () {
      return _userRef(uid).child('shopProgress').onValue.map((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return {'adsForAutoMiningDay': 0, 'autoMiningDayUnlocked': false, 'usedAutoMiningDayAt': null};
      }).asBroadcastStream();
    });
  }

  /// Watch 1 ad toward Auto mining 1 day pack. Returns new count (0-5). At 5, unlocks pack.
  Future<int> incrementAutoMiningDayAds(String uid) async {
    final ref = _userRef(uid).child('shopProgress');
    final snap = await ref.get();
    final data = snap.value as Map<dynamic, dynamic>?;
    final current = (data?['adsForAutoMiningDay'] is num) ? (data!['adsForAutoMiningDay'] as num).toInt() : 0;
    final next = (current + 1).clamp(0, 5);
    await ref.update({'adsForAutoMiningDay': next});
    if (next >= 5) {
      await ref.update({'autoMiningDayUnlocked': true});
    }
    return next;
  }

  /// Use the Auto mining 1 day pack (must be unlocked). Starts 24h session and marks as used.
  Future<bool> useAutoMiningDayPack(String uid, double balanceAtStart) async {
    final snap = await _userRef(uid).child('shopProgress').get();
    final data = snap.value as Map<dynamic, dynamic>?;
    final unlocked = data?['autoMiningDayUnlocked'] == true;
    final usedAt = data?['usedAutoMiningDayAt'];
    if (!unlocked || (usedAt is num && usedAt > 0)) return false;
    await _userRef(uid).child('shopProgress').update({
      'usedAutoMiningDayAt': ServerValue.timestamp,
      'autoMiningDayUnlocked': false,
      'adsForAutoMiningDay': 0,
    });
    await startMining(uid, balanceAtStart: balanceAtStart, sessionDurationHours: 24);
    return true;
  }

  /// Add progress (e.g. from Lucky Spin) to a shop item. Unlocks when ads count >= required.
  Future<int> addShopProgress(String uid, String itemId, int amount) async {
    final item = ShopItem.byId(itemId);
    if (item == null || amount <= 0) return 0;
    final ref = _userRef(uid).child('shopProgress');
    final key = 'adsFor${itemId[0].toUpperCase()}${itemId.substring(1)}';
    final unlockKey = _shopUnlockKey(itemId);
    final snap = await ref.get();
    final data = snap.value as Map<dynamic, dynamic>? ?? {};
    final current = (data[key] is num) ? (data[key] as num).toInt() : 0;
    final next = (current + amount).clamp(0, item.adsRequired);
    await ref.update({key: next});
    if (next >= item.adsRequired) {
      await ref.update({unlockKey: true});
      if (item.type == 'rig') await _recomputeRigBonus(uid);
    }
    return next;
  }

  static String _shopUnlockKey(String itemId) {
    switch (itemId) {
      case 'rig1': return 'rig1Unlocked';
      case 'rig2': return 'rig2Unlocked';
      case 'rig3': return 'rig3Unlocked';
      case 'megaBoost': return 'megaBoostUnlocked';
      case 'autoMiningDay': return 'autoMiningDayUnlocked';
      case 'doubleSession': return 'doubleSessionAvailable';
      default: return '${itemId}Unlocked';
    }
  }

  static String _shopAdsKey(String itemId) {
    return 'adsFor${itemId[0].toUpperCase()}${itemId.substring(1)}';
  }

  Future<void> _recomputeRigBonus(String uid) async {
    final shopSnap = await _userRef(uid).child('shopProgress').get();
    final data = shopSnap.value as Map<dynamic, dynamic>? ?? {};
    double total = 0;
    for (final rig in ShopItem.rigs) {
      final key = _shopUnlockKey(rig.id);
      if (data[key] == true) total += rig.rigBonusPercent;
    }
    await _userRef(uid).child('stats').update({'rigBonusPercent': total});
  }

  /// Use Mega Boost (2x for 1h). Consumes unlock.
  Future<bool> useMegaBoost(String uid) async {
    final snap = await _userRef(uid).child('shopProgress').get();
    final data = snap.value as Map<dynamic, dynamic>?;
    if (data?['megaBoostUnlocked'] != true) return false;
    await _userRef(uid).child('shopProgress').update({
      'megaBoostUnlocked': false,
      'adsForMegaBoost': 0,
    });
    await applyBoost(uid, multiplier: 2.0, durationMinutes: 60);
    return true;
  }

  /// Consume Double Session: next Start Mining will be 8h. Call before startMining.
  Future<bool> useDoubleSession(String uid) async {
    final snap = await _userRef(uid).child('shopProgress').get();
    final data = snap.value as Map<dynamic, dynamic>?;
    if (data?['doubleSessionAvailable'] != true) return false;
    await _userRef(uid).child('shopProgress').update({
      'doubleSessionAvailable': false,
      'adsForDoubleSession': 0,
      'nextSessionHours': 8,
    });
    return true;
  }

  /// Returns next session hours (8 if double session consumed, else 4). Clears nextSessionHours after read.
  Future<int> consumeNextSessionHours(String uid) async {
    final snap = await _userRef(uid).child('shopProgress').get();
    final data = snap.value as Map<dynamic, dynamic>?;
    final hours = (data?['nextSessionHours'] is num) ? (data!['nextSessionHours'] as num).toInt() : defaultSessionHours;
    if (hours == 8) {
      await _userRef(uid).child('shopProgress').update({'nextSessionHours': null});
    }
    return hours;
  }

  Future<void> updateStats(String uid, Map<String, Object?> updates) async {
    await _userRef(uid).child('stats').update(updates);
  }

  /// Claim daily login bonus. Allowed once per calendar day. Returns true if claimed, false if already claimed today.
  /// Updates balance, rewardStreak (consecutive days), and lastDailyClaimAt.
  Future<bool> claimDailyLogin(String uid) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final statsRef = _userRef(uid).child('stats');
    final snap = await statsRef.get();
    if (!snap.exists) return false;
    final data = snap.value as Map<dynamic, dynamic>? ?? {};
    final lastMs = data['lastDailyClaimAt'];
    final lastClaimAt = lastMs is num ? lastMs.toInt() : 0;
    if (lastClaimAt >= todayStart) return false;

    final yesterdayStart = todayStart - 24 * 3600 * 1000;
    final currentStreak = (data['rewardStreak'] is num) ? (data['rewardStreak'] as num).toInt() : 0;
    final newStreak = (lastClaimAt >= yesterdayStart && lastClaimAt < todayStart) ? currentStreak + 1 : 1;

    final balance = (data['balanceBtc'] is num) ? (data['balanceBtc'] as num).toDouble() : 0.0;
    final newBalance = balance + MiningConstants.dailyLoginBonusBtc;

    await statsRef.update({
      'balanceBtc': newBalance,
      'rewardStreak': newStreak,
      'lastDailyClaimAt': now.millisecondsSinceEpoch,
    });
    await _userRef(uid).child('activity').push().set({
      'type': 'daily_login',
      'label': 'Daily login +${MiningConstants.dailyLoginBonusBtc} BTC',
      'createdAt': ServerValue.timestamp,
    });
    return true;
  }

  /// Fetch leaderboard: top 53 users by balance (for top 3 cards + 50 list). Sorted by balanceBtc descending.
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final usersSnap = await _db.ref('users').get();
    if (!usersSnap.exists) return [];
    final usersMap = usersSnap.value as Map<dynamic, dynamic>?;
    if (usersMap == null) return [];

    final list = <LeaderboardEntry>[];
    for (final entry in usersMap.entries) {
      final uid = entry.key.toString();
      final userData = entry.value;
      if (userData is! Map) continue;
      final stats = userData['stats'];
      final profile = userData['profile'];
      final balance = (stats is Map && stats['balanceBtc'] is num)
          ? (stats['balanceBtc'] as num).toDouble()
          : 0.0;
      final name = (profile is Map && profile['name'] != null)
          ? profile['name'].toString()
          : 'Miner';
      list.add(LeaderboardEntry(rank: 0, uid: uid, displayName: name, balanceBtc: balance));
    }
    list.sort((a, b) => b.balanceBtc.compareTo(a.balanceBtc));
    return list.take(53).toList().asMap().entries.map((e) {
      return LeaderboardEntry(
        rank: e.key + 1,
        uid: e.value.uid,
        displayName: e.value.displayName,
        balanceBtc: e.value.balanceBtc,
      );
    }).toList();
  }

  /// Ensure monthKey and earnedThisMonth exist; reset earnedThisMonth if month changed.
  Future<void> ensureMonthStats(String uid) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final ref = _userRef(uid).child('stats');
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.value as Map<dynamic, dynamic>?;
    final currentKey = data?['monthKey']?.toString() ?? '';
    if (currentKey != key) {
      await ref.update({'monthKey': key, 'earnedThisMonth': 0.0});
    }
  }

  Future<void> requestBoost({
    required String uid,
    required String pack,
    required String price,
  }) async {
    await _userRef(uid).child('boosts').push().set({
      'pack': pack,
      'price': price,
      'status': 'queued',
      'createdAt': ServerValue.timestamp,
    });
    await _userRef(uid).child('activity').push().set({
      'type': 'boost',
      'label': pack,
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> requestWithdraw({
    required String uid,
    required String wallet,
    required String network,
    required String amount,
  }) async {
    await _userRef(uid).child('withdrawals').push().set({
      'wallet': wallet,
      'network': network,
      'amount': amount,
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
    });
    await _userRef(uid).child('activity').push().set({
      'type': 'withdraw',
      'label': amount,
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<List<TransactionItem>> withdrawalsStream(String uid) {
    return _withdrawalsStreamCache.putIfAbsent(uid, () {
      return _userRef(uid).child('withdrawals').onValue.map<List<TransactionItem>>((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          return data.entries.map((entry) {
            final value = entry.value;
            if (value is Map) {
              final map = Map<String, dynamic>.from(value);
              return TransactionItem.fromWithdrawal(id: entry.key, data: map);
            }
            return null;
          }).whereType<TransactionItem>().toList();
        }
        return <TransactionItem>[];
      }).asBroadcastStream();
    });
  }

  Stream<List<TransactionItem>> boostsStream(String uid) {
    return _boostsStreamCache.putIfAbsent(uid, () {
      return _userRef(uid).child('boosts').onValue.map<List<TransactionItem>>((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          return data.entries.map((entry) {
            final value = entry.value;
            if (value is Map) {
              final map = Map<String, dynamic>.from(value);
              return TransactionItem.fromBoost(id: entry.key, data: map);
            }
            return null;
          }).whereType<TransactionItem>().toList();
        }
        return <TransactionItem>[];
      }).asBroadcastStream();
    });
  }

  /// Recent activity stream (mining start/stop, boost, withdraw). Sorted by createdAt descending.
  Stream<List<ActivityItem>> activityStream(String uid) {
    return _activityStreamCache.putIfAbsent(uid, () {
      return _userRef(uid).child('activity').onValue.map<List<ActivityItem>>((event) {
        final data = event.snapshot.value;
        if (data is Map) {
          final list = data.entries.map((entry) {
            final value = entry.value;
            if (value is Map) {
              return ActivityItem.fromMap(entry.key.toString(), Map<String, dynamic>.from(value));
            }
            return null;
          }).whereType<ActivityItem>().toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.take(15).toList();
        }
        return <ActivityItem>[];
      }).asBroadcastStream();
    });
  }
}
