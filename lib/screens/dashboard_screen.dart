import 'dart:async';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../models/activity_item.dart';
import '../models/user_stats.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/remote_config_service.dart';
import '../services/ad_service.dart';
import '../services/kas_price_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../widgets/activity_tile.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/native_ad_placeholder.dart';
import '../widgets/stat_pill.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  StreamSubscription<UserStats>? _statsSub;
  StreamSubscription<Map<String, dynamic>>? _miningSub;
  Timer? _timer;
  UserStats _stats = UserStats.initial();
  bool _miningActive = false;
  DateTime? _miningStartedAt;
  double _balanceAtStart = 0.0;
  double _liveBalance = 0.0;
  String _liveUptime = '00:00:00';
  int _tick = 0;
  double _boostMultiplier = 1.0;
  int? _boostEndsAtMs;
  int? _sessionEndsAtMs;
  int _sessionDurationHours = 4;
  double _earnedThisMonth = 0.0;
  String _monthKey = '';
  double _sessionEarned = 0.0;
  DateTime? _backgroundedAt;

  double get _baseRate => DatabaseService.miningEarningsPerSecond;
  double get _rigMultiplier => 1.0 + (_stats.rigBonusPercent / 100.0);
  double get _effectiveRate => _baseRate * _boostMultiplier * _rigMultiplier;

  /// Hashrate shown in balance card: computed from effective rate when mining, else from stats.
  String get _displayHashrate {
    if (_effectiveRate > 0) {
      final thPerSec = _effectiveRate * 1e6;
      if (thPerSec >= 1000) return '${(thPerSec / 1000).toStringAsFixed(2)} PH/s';
      if (thPerSec >= 1) return '${thPerSec.toStringAsFixed(2)} TH/s';
      if (thPerSec >= 0.001) return '${(thPerSec * 1000).toStringAsFixed(2)} GH/s';
      return '${(thPerSec * 1e6).toStringAsFixed(2)} MH/s';
    }
    return _stats.hashrate;
  }

  double? _kasPriceUsd;
  List<KasPricePoint> _kasHistory = [];
  bool _kasLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final user = AuthService.instance.currentUser;
    if (user == null) return;

    DatabaseService.instance.ensureMonthStats(user.uid);

    _statsSub = DatabaseService.instance.statsStream(user.uid).listen((stats) {
      if (mounted) {
        setState(() {
          _stats = stats;
          _earnedThisMonth = stats.earnedThisMonth;
          _monthKey = stats.monthKey;
          if (!_miningActive) {
            _liveBalance = stats.balanceBtc;
            _liveUptime = stats.sessionUptime;
            _sessionEarned = 0.0;
          }
        });
      }
    });

    void applyMiningState(Map<String, dynamic> data) {
      final active = data['active'] == true;
      final startedAt = data['startedAt'];
      final balanceAtStart = data['balanceAtStart'];
      final boostMult = data['boostMultiplier'];
      final boostEnds = data['boostEndsAt'];
      final sessionEnds = data['sessionEndsAt'];
      final sessionHours = data['sessionDurationHours'];
      DateTime? started;
      if (startedAt is num) {
        started = DateTime.fromMillisecondsSinceEpoch(startedAt.toInt());
      }
      final base = (balanceAtStart is num) ? balanceAtStart.toDouble() : 0.0;
      if (mounted) {
        setState(() {
          _miningActive = active;
          _miningStartedAt = started;
          _balanceAtStart = base;
          _boostMultiplier = (boostMult is num) ? boostMult.toDouble() : 1.0;
          _boostEndsAtMs = (boostEnds is num) ? boostEnds.toInt() : null;
          _sessionEndsAtMs = (sessionEnds is num) ? sessionEnds.toInt() : null;
          _sessionDurationHours =
              (sessionHours is num) ? sessionHours.toInt() : 4;
          if (!active) {
            _liveBalance = _stats.balanceBtc;
            _liveUptime = _stats.sessionUptime;
            _sessionEarned = 0.0;
          } else {
            _liveBalance = base;
            _liveUptime = started != null
                ? _formatDuration(DateTime.now().difference(started))
                : '00:00:00';
          }
        });
      }
      if (active) {
        _startTicker();
      } else {
        _stopTicker();
      }
    }

    // Load current mining state immediately so button state is correct when returning to dashboard
    DatabaseService.instance.getMiningState(user.uid).then(applyMiningState);

    _miningSub = DatabaseService.instance.miningStream(user.uid).listen(applyMiningState);

    _loadKasPrice();
    AdService.instance.loadRewardedAd();
    AdService.instance.loadInterstitialAd();
  }

  Future<void> _loadKasPrice() async {
    setState(() => _kasLoading = true);
    final price = await KasPriceService.instance.getCurrentPrice();
    final history = await KasPriceService.instance.getPriceHistory(days: 7);
    if (mounted) {
      setState(() {
        _kasPriceUsd = price;
        _kasHistory = history;
        _kasLoading = false;
      });
    }
  }

  void _updateBoostFromTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_boostEndsAtMs != null && now >= _boostEndsAtMs!) {
      if (mounted) {
        setState(() {
          _boostMultiplier = 1.0;
          _boostEndsAtMs = null;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statsSub?.cancel();
    _miningSub?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    if (!_miningActive || _backgroundedAt == null) {
      _backgroundedAt = null;
      return;
    }
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _backgroundedAt = null;
      return;
    }
    _updateBoostFromTime();
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final backgroundedAt = _backgroundedAt!;
    _backgroundedAt = null;

    if (_sessionEndsAtMs != null && nowMs >= _sessionEndsAtMs!) {
      await DatabaseService.instance.stopMining(
        user.uid,
        finalBalanceBtc: _liveBalance,
        finalSessionUptime: _liveUptime,
      );
      await NotificationService.instance.showMiningEnded();
      if (mounted) {
        setState(() {
          _miningActive = false;
          _liveBalance = _stats.balanceBtc;
          _sessionEarned = 0.0;
        });
      }
      _stopTicker();
      return;
    }

    final elapsed = now.difference(backgroundedAt);
    final elapsedSec = elapsed.inSeconds.clamp(0, 86400 * 365);
    if (elapsedSec <= 0) return;

    final remaining =
        (MiningConstants.maxBtcPerMonth - _earnedThisMonth).clamp(0.0, double.infinity);
    var catchUp = (elapsedSec * _effectiveRate).clamp(0.0, remaining);
    if (_sessionEndsAtMs != null) {
      final sessionEndAt = DateTime.fromMillisecondsSinceEpoch(_sessionEndsAtMs!);
      final maxEarnSec = sessionEndAt.difference(backgroundedAt).inSeconds.clamp(0, elapsedSec);
      final maxCatchUp = maxEarnSec * _effectiveRate;
      if (catchUp > maxCatchUp) catchUp = maxCatchUp.clamp(0.0, remaining);
    }
    _sessionEarned += catchUp;
    _liveBalance = _balanceAtStart + _sessionEarned;
    _earnedThisMonth += catchUp;
    _liveUptime = _formatDuration(now.difference(_miningStartedAt ?? now));

    final monthKey = _monthKey.isEmpty
        ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
        : _monthKey;
    await DatabaseService.instance.updateStats(user.uid, {
      'balanceBtc': _liveBalance,
      'sessionUptime': _liveUptime,
      'lastSyncAt': nowMs,
      'earnedThisMonth': _earnedThisMonth,
      'monthKey': monthKey,
    });

    if (mounted) setState(() {});
  }

  void _startTicker() {
    _timer?.cancel();
    final startedAt = _miningStartedAt;
    if (startedAt != null) {
      final elapsed = DateTime.now().difference(startedAt);
      final elapsedSec = elapsed.inSeconds.clamp(0, 86400 * 365);
      final remaining =
          (MiningConstants.maxBtcPerMonth - _earnedThisMonth).clamp(0.0, double.infinity);
      final catchUp =
          (elapsedSec * _effectiveRate).clamp(0.0, remaining);
      _sessionEarned = catchUp;
      _liveBalance = _balanceAtStart + _sessionEarned;
      _earnedThisMonth += catchUp;
      _liveUptime = _formatDuration(elapsed);
      if (mounted) setState(() {});
    } else {
      _sessionEarned = 0.0;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_miningActive) return;
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;
      if (_sessionEndsAtMs != null && nowMs >= _sessionEndsAtMs!) {
        final user = AuthService.instance.currentUser;
        if (user != null) {
          await DatabaseService.instance.stopMining(
            user.uid,
            finalBalanceBtc: _liveBalance,
            finalSessionUptime: _liveUptime,
          );
          await NotificationService.instance.showMiningEnded();
        }
        _stopTicker();
        if (mounted) setState(() {});
        return;
      }
      _updateBoostFromTime();
      final startedAt = _miningStartedAt;
      final elapsed =
      startedAt != null ? now.difference(startedAt) : Duration.zero;
      final uptime = _formatDuration(elapsed);
      final remaining = (MiningConstants.maxBtcPerMonth - _earnedThisMonth)
          .clamp(0.0, double.infinity);
      final deltaThisSecond = _effectiveRate;
      final allowed = remaining > 0
          ? (deltaThisSecond > remaining ? remaining : deltaThisSecond)
          : 0.0;
      _sessionEarned += allowed;
      final newEarnedThisMonth = _earnedThisMonth + allowed;
      final balance = _balanceAtStart + _sessionEarned;

      if (mounted) {
        setState(() {
          _liveUptime = uptime;
          _liveBalance = balance;
          _earnedThisMonth = newEarnedThisMonth;
        });
      }

      _tick += 1;
      if (_tick % 5 == 0) {
        final user = AuthService.instance.currentUser;
        if (user == null) return;
        final monthKey = _monthKey.isEmpty
            ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
            : _monthKey;
        DatabaseService.instance.updateStats(user.uid, {
          'balanceBtc': balance,
          'sessionUptime': uptime,
          'lastSyncAt': nowMs,
          'earnedThisMonth': newEarnedThisMonth,
          'monthKey': monthKey,
        });
      }
    });
  }

  void _stopTicker() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatActivityTime(int createdAt) {
    if (createdAt <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _activityTileFromItem(ActivityItem a) {
    String title;
    String subtitle;
    String value;
    switch (a.type) {
      case 'mining_start':
        title = 'Mining started';
        subtitle = '${a.label} • ${_formatActivityTime(a.createdAt)}';
        value = '—';
        break;
      case 'mining_stop':
        title = 'Mining stopped';
        subtitle = _formatActivityTime(a.createdAt);
        value = '—';
        break;
      case 'boost':
        title = 'Boost applied';
        subtitle = '${a.label} • ${_formatActivityTime(a.createdAt)}';
        value = '+2x';
        break;
      default:
        title = a.label;
        subtitle = _formatActivityTime(a.createdAt);
        value = '—';
    }
    return ActivityTile(title: title, subtitle: subtitle, value: value);
  }

  Future<void> _toggleMining() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    if (_miningActive) {
      await DatabaseService.instance.stopMining(
        user.uid,
        finalBalanceBtc: _liveBalance,
        finalSessionUptime: _liveUptime,
      );
      await NotificationService.instance.showMiningEnded();
      if (!mounted) return;
      AdService.instance.tryShowInterstitialRandomly();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mining stopped'),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      final sessionHours =
      await DatabaseService.instance.consumeNextSessionHours(user.uid);
      await DatabaseService.instance.startMining(
        user.uid,
        balanceAtStart: _stats.balanceBtc,
        sessionDurationHours: sessionHours,
      );
      final sessionEndsAt = DateTime.now().add(Duration(hours: sessionHours));
      await NotificationService.instance.showMiningStarted(
        sessionHours: sessionHours,
        sessionEndsAt: sessionEndsAt,
      );
      if (!mounted) return;
      AdService.instance.tryShowInterstitialRandomly();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mining started for $sessionHours hours'),
          backgroundColor: const Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _watchAdForBoost({required int durationMinutes}) async {
    if (!AdService.instance.isRewardedAdReady) {
      AdService.instance.loadRewardedAd(
        onLoaded: () {
          if (mounted) {
            _showRewardedAdForBoost(durationMinutes: durationMinutes);
          }
        },
        onFailed: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ad not ready. Try again soon.'),
                backgroundColor: const Color(0xFFFF6B00),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      );
      return;
    }
    await _showRewardedAdForBoost(durationMinutes: durationMinutes);
  }

  Future<void> _watchAdForDayBoost() async {
    if (!AdService.instance.isRewardedAdReady) {
      AdService.instance.loadRewardedAd(
        onLoaded: () {
          if (mounted) _showRewardedAdForDayBoost();
        },
        onFailed: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Ad not ready. Try again soon.'),
                backgroundColor: const Color(0xFFFF6B00),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      );
      return;
    }
    await _showRewardedAdForDayBoost();
  }

  Future<void> _showRewardedAdForBoost({required int durationMinutes}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    const mult = 2.0;
    await AdService.instance.showRewardedAd(
      onReward: () async {
        await DatabaseService.instance.applyBoost(
          user.uid,
          multiplier: mult,
          durationMinutes: durationMinutes,
        );
        final durationText =
        durationMinutes >= 60 ? '${durationMinutes ~/ 60}h' : '${durationMinutes}min';
        await NotificationService.instance.showBoostActivated(
          title: 'Boost activated',
          body: '${mult}x mining for $durationText. You\'re earning faster!',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text('${mult}x boost for $durationMinutes min! Mining faster.'),
              duration: const Duration(seconds: 4),
              backgroundColor: const Color(0xFF00C853),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      onFailed: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ad failed: $msg'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _showRewardedAdForDayBoost() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    await AdService.instance.showRewardedAd(
      onReward: () async {
        final newCount =
        await DatabaseService.instance.incrementDayBoostAds(user.uid);
        if (newCount == 0) {
          await NotificationService.instance.showBoostActivated(
            title: '1-day boost activated',
            body: '2x mining for 24 hours. You\'re earning faster!',
          );
        }
        if (mounted) {
          if (newCount == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('1-day 2x boost activated! Mining faster.'),
                duration: Duration(seconds: 4),
                backgroundColor: Color(0xFF00C853),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$newCount/5 ads for 1-day boost. Watch more!'),
                backgroundColor: const Color(0xFF2196F3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      onFailed: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ad failed: $msg'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Sign in to view your dashboard.'),
      );
    }
    final monthCapProgress = MiningConstants.maxBtcPerMonth > 0
        ? (_earnedThisMonth / MiningConstants.maxBtcPerMonth).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            child: ListView(
              key: const PageStorageKey<String>('dashboard_list'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.screenPaddingH,
                vertical: AppTheme.screenPaddingV,
              ),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                _buildHeader(),
                const SizedBox(height: AppTheme.sectionSpacing),
                LayoutBuilder(
                  builder: (context, c) => _buildBalanceAndPriceSection(c.maxWidth),
                ),
                const SizedBox(height: AppTheme.sectionSpacing),
                _buildMiningButton(),
                const SizedBox(height: AppTheme.cardSpacing),
                _buildSectionLabel('Mining stats'),
                const SizedBox(height: 8),
                _buildMiningPowerCard(monthCapProgress),
                const SizedBox(height: AppTheme.cardSpacing),
                if (RemoteConfigService.instance.rewardedAdsEnabled) ...[
                  _buildBoostSection(),
                  const SizedBox(height: AppTheme.cardSpacing),
                ],
                const NativeAdPlaceholder(key: ValueKey('dashboard_native_ad')),
                const SizedBox(height: AppTheme.sectionSpacing),
                _buildSectionLabel('Recent activity'),
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: ValueKey('activity_${user.uid}'),
                  child: _buildActivitySection(user.uid),
                ),
                const SizedBox(height: AppTheme.sectionSpacing),
                const BannerAdWidget(key: ValueKey('dashboard_banner')),
                const SizedBox(height: AppTheme.cardSpacing),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitor your Kaspa mining activity',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Balance and KAS price: side-by-side on wide screens, stacked on narrow.
  Widget _buildBalanceAndPriceSection(double width) {
    if (width > 420) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildBalanceCard()),
          const SizedBox(width: AppTheme.cardSpacing),
          Expanded(child: _buildBtcPriceCard()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBalanceCard(),
        const SizedBox(height: AppTheme.cardSpacing),
        _buildBtcPriceCard(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.balanceCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _miningActive ? 'Total Balance (updating)' : 'Total Balance',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_miningActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                MiningConstants.formatBtcFull(_liveBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'KAS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (_kasPriceUsd != null) ...[
              const SizedBox(height: 4),
              Text(
              '≈ \$${(_liveBalance * _kasPriceUsd!).toStringAsFixed(2)} USD',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceMetric(
                  label: 'Hashrate',
                  value: _displayHashrate,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: _buildBalanceMetric(
                  label: 'Active Rigs',
                  value: _stats.activeRigs.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceMetric({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBtcPriceCard() {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppGradients.eth,
                      borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.diamond_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kaspa',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'KAS / USD',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_kasLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Text(
                  _kasPriceUsd != null
                      ? '\$${_formatPrice(_kasPriceUsd!)}'
                      : '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 84,
            child: _kasLoading && _kasHistory.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : _buildKasChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildKasChart() {
    final points = _kasHistory;
    final price = _kasPriceUsd;
    final List<KasPricePoint> chartPoints = points.isNotEmpty
        ? points
        : (price != null && price > 0)
            ? _fallbackChartPoints(price)
            : <KasPricePoint>[];
    if (chartPoints.isEmpty) {
      return Center(
        child: Text(
          'Price data unavailable',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }
    final prices = chartPoints.map((e) => e.priceUsd).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b);
    final maxY = prices.reduce((a, b) => a > b ? a : b);
    final span = (maxY - minY).clamp(0.0001, double.infinity);
    final spots = chartPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.priceUsd);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY - span * 0.1,
        maxY: maxY + span * 0.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.chartAccent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.chartAccent.withOpacity(0.15),
                  AppColors.chartAccent.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  String _formatPrice(double usd) {
    if (usd >= 1) return usd.toStringAsFixed(2);
    if (usd >= 0.01) return usd.toStringAsFixed(4);
    return usd.toStringAsFixed(6);
  }

  List<KasPricePoint> _fallbackChartPoints(double currentPrice) {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final weekAgo = now - 7 * 24 * 60 * 60 * 1000;
    return [
      KasPricePoint(weekAgo, currentPrice * 0.98),
      KasPricePoint(now, currentPrice),
    ];
  }

  String _sessionTimeLeft() {
    if (_sessionEndsAtMs == null) return '';
    final left = _sessionEndsAtMs! - DateTime.now().millisecondsSinceEpoch;
    if (left <= 0) return '0:00:00';
    final h = left ~/ (3600 * 1000);
    final m = (left % (3600 * 1000)) ~/ (60 * 1000);
    final s = (left % (60 * 1000)) ~/ 1000;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildMiningPowerCard(double monthCapProgress) {
    final effectiveRate = _effectiveRate;
    final isCapped = _earnedThisMonth >= MiningConstants.maxBtcPerMonth;

    return Container(
      padding: AppTheme.cardPadding,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mining Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (_miningActive && _sessionEndsAtMs != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardTint,
                borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Session: ${_sessionDurationHours}h',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_sessionTimeLeft()} left',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoRow('Session uptime', _liveUptime),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Mining rate',
            '${MiningConstants.formatBtcRate(effectiveRate)}/sec',
          ),
          if (_boostMultiplier > 1.0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.rocket_launch,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_boostMultiplier}x boost',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly cap',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${MiningConstants.formatBtcFull(_earnedThisMonth)} / ${MiningConstants.formatBtcFull(MiningConstants.maxBtcPerMonth)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: monthCapProgress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCapped ? const Color(0xFFE53935) : AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBoostSection() {
    final user = AuthService.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Boost Earnings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildBoostCard(
          title: '1 min',
          subtitle: 'Quick boost',
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          onTap: () => _watchAdForBoost(durationMinutes: 1),
        ),
        const SizedBox(height: 8),
        _buildBoostCard(
          title: '3 min',
          subtitle: 'Extended',
          gradient: const LinearGradient(
            colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          ),
          onTap: () => _watchAdForBoost(durationMinutes: 3),
        ),
        const SizedBox(height: 8),
        StreamBuilder<Map<String, dynamic>>(
          stream: DatabaseService.instance.boostProgressStream(user.uid),
          builder: (context, progressSnap) {
            final ads = progressSnap.data?['adsForDayBoost'] ?? 0;
            final count = ads is int ? ads : (ads is num ? ads.toInt() : 0);
            return _buildBoostCard(
              title: '1 day',
              subtitle: '$count/5 ads',
              gradient: const LinearGradient(
                colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
              ),
              onTap: _watchAdForDayBoost,
              progress: count / 5,
            );
          },
        ),
      ],
    );
  }

  Widget _buildBoostCard({
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    double? progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiningButton() {
    final isCapped =
        _earnedThisMonth >= MiningConstants.maxBtcPerMonth && _miningActive;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _miningActive ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: isCapped
              ? LinearGradient(
            colors: [AppColors.border, AppColors.textSecondary],
          )
              : _miningActive
              ? const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF00E676)],
          )
              : const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isCapped
                  ? AppColors.textSecondary
                  : _miningActive
                  ? const Color(0xFF00C853)
                  : AppColors.primaryDark)
                  .withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isCapped ? null : _toggleMining,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_miningActive)
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 18,
                      height: 18,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.power_settings_new,
                        color: isCapped ? AppColors.textSecondary : Colors.white,
                        size: 20,
                      ),
                    ),
                  Text(
                    isCapped
                        ? 'Monthly cap reached'
                        : _miningActive
                        ? 'Mining'
                        : 'Start Mining',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCapped ? AppColors.textPrimary : Colors.white,
                    ),
                  ),
                  if (_miningActive && !isCapped)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '(tap to stop)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<ActivityItem>>(
          stream: DatabaseService.instance.activityStream(userId),
          builder: (context, snap) {
            final activities = (snap.data ?? [])
                .where((a) => a.type != 'withdraw')
                .toList();

            if (activities.isEmpty) {
              return Container(
                padding: AppTheme.cardPadding,
                decoration: AppTheme.cardDecoration(),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 40,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No activity yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start mining to see activity',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: activities
                    .map((a) => _activityTileFromItem(a))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}