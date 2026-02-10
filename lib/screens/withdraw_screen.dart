import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/eth_price_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../widgets/app_text_field.dart';
import '../widgets/native_ad_placeholder.dart';

const _networks = [
  'Ethereum Mainnet',
  'Polygon',
  'Arbitrum One',
  'Optimism',
  'BNB Smart Chain',
];

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _walletController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = false;
  double? _currentBalance;
  double? _fetchedBalance;
  double? _ethPriceUsd;
  int _withdrawAdsWatched = 0;
  String _selectedNetwork = _networks[0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.tryShowInterstitialRandomly();
      _loadEthPrice();
      _loadWithdrawAdsProgress();
      _fetchBalanceOnce();
      AdService.instance.loadRewardedAd();
    });
  }

  Future<void> _fetchBalanceOnce() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final stats = await DatabaseService.instance.getUserStats(user.uid);
    if (mounted) setState(() => _fetchedBalance = stats.balanceBtc);
  }

  Future<void> _loadEthPrice() async {
    final price = await EthPriceService.instance.getCurrentPrice();
    if (mounted) setState(() => _ethPriceUsd = price);
  }

  Future<void> _loadWithdrawAdsProgress() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final count = await DatabaseService.instance.getWithdrawAdsWatched(user.uid);
    if (mounted) setState(() => _withdrawAdsWatched = count);
  }

  @override
  void dispose() {
    _walletController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? get _minEthForWithdraw {
    if (_ethPriceUsd == null || _ethPriceUsd! <= 0) return null;
    return MiningConstants.effectiveWithdrawThresholdUsd / _ethPriceUsd!;
  }

  /// True when balance (in USD) meets or exceeds the minimum withdrawal threshold.
  /// Tiny tolerance to avoid float rounding (e.g. 99.999999) keeping the button disabled.
  bool _canWithdraw(double balance) {
    if (_ethPriceUsd == null || _ethPriceUsd! <= 0) return false;
    const toleranceUsd = 0.001;
    return balance * _ethPriceUsd! >= MiningConstants.effectiveWithdrawThresholdUsd - toleranceUsd;
  }

  /// Only show "need X ETH more" when shortfall is meaningful (avoids rounding and stale balance).
  bool _shouldShowKeepMining(double balance, double? minEth) {
    if (minEth == null || _canWithdraw(balance)) return false;
    const minShortfallEth = 0.00001;
    return (minEth - balance) > minShortfallEth;
  }

  bool get _hasCompletedWithdrawAds => _withdrawAdsWatched >= DatabaseService.withdrawAdsRequired;

  void _onRequestWithdrawalPressed(double balance) {
    if (!_canWithdraw(balance)) return;
    if (!_hasCompletedWithdrawAds) {
      _showWatchAdsDialog();
      return;
    }
    _submit();
  }

  void _showWatchAdsDialog() {
    AdService.instance.loadRewardedAd();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WithdrawAdsDialog(
        currentCount: _withdrawAdsWatched,
        requiredCount: DatabaseService.withdrawAdsRequired,
        onWatchAd: () async {
          final user = AuthService.instance.currentUser;
          if (user == null) return;
          if (!AdService.instance.isRewardedAdReady) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ad is loading. Please try again in a moment.')),
              );
            }
            AdService.instance.loadRewardedAd();
            return;
          }
          await AdService.instance.showRewardedAd(
            onReward: () async {
              AdService.instance.loadRewardedAd();
              final next = await DatabaseService.instance.incrementWithdrawAdsWatched(user.uid);
              if (!mounted) return;
              setState(() => _withdrawAdsWatched = next);
              Navigator.of(context).pop();
              if (next >= DatabaseService.withdrawAdsRequired) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You can now submit your withdrawal.')),
                );
              } else {
                _showWatchAdsDialog();
              }
            },
            onFailed: (msg) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            },
          );
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _submit() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    if (_walletController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter wallet and amount.')),
      );
      return;
    }
    final amountStr = _amountController.text.trim().replaceAll(RegExp(r'\s*ETH\s*', caseSensitive: false), '').trim();
    final amount = double.tryParse(amountStr);
    final minEth = _minEthForWithdraw;
    if (amount == null || minEth == null || amount < minEth) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            minEth != null
                ? 'Minimum withdrawal is ~\$${MiningConstants.effectiveWithdrawThresholdUsd.toStringAsFixed(MiningConstants.withdrawTestMode ? 2 : 0)} worth (${MiningConstants.formatEthFull(minEth)} ETH).'
                : 'Loading price…',
          ),
        ),
      );
      return;
    }
    final balance = _currentBalance;
    if (balance != null && amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds your balance.')),
      );
      return;
    }
    setState(() => _loading = true);
    await DatabaseService.instance.requestWithdraw(
      uid: user.uid,
      wallet: _walletController.text.trim(),
      network: _selectedNetwork,
      amount: '$amountStr ETH',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _walletController.clear();
    _amountController.clear();
    _loadWithdrawAdsProgress();
    AdService.instance.tryShowInterstitialRandomly();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Withdrawal requested.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw'),
        backgroundColor: AppColors.surface,
      ),
      body: StreamBuilder(
        stream: AuthService.instance.currentUser != null
            ? DatabaseService.instance.statsStream(AuthService.instance.currentUser!.uid)
            : null,
        builder: (context, snap) {
          _currentBalance = snap.data?.balanceBtc ?? _fetchedBalance;
          final balance = _currentBalance ?? 0.0;
          final canWithdraw = _canWithdraw(balance);
          final minEth = _minEthForWithdraw;
          final balanceUsd = _ethPriceUsd != null ? balance * _ethPriceUsd! : null;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          gradient: AppGradients.eth,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: AppTheme.balanceCardShadow,
        ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdraw ETH when balance is ~\$${MiningConstants.effectiveWithdrawThresholdUsd.toStringAsFixed(MiningConstants.withdrawTestMode ? 2 : 0)} worth.',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Balance: ${MiningConstants.formatEthFull(balance)} ETH${balanceUsd != null ? ' (≈ \$${balanceUsd.toStringAsFixed(2)})' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      minEth != null
                          ? 'Min. withdraw: ~\$${MiningConstants.effectiveWithdrawThresholdUsd.toStringAsFixed(MiningConstants.withdrawTestMode ? 2 : 0)} (${MiningConstants.formatEthFull(minEth)} ETH)'
                          : 'Min. withdraw: loading…',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    if (MiningConstants.withdrawTestMode) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Test mode: min balance ~\$0.01',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (canWithdraw) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardTint,
                    borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Withdrawal requirement: watch ${DatabaseService.withdrawAdsRequired} ads',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _withdrawAdsWatched / DatabaseService.withdrawAdsRequired,
                                minHeight: 8,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _hasCompletedWithdrawAds ? AppColors.success : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_withdrawAdsWatched / ${DatabaseService.withdrawAdsRequired}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Progress is saved. Complete all ${DatabaseService.withdrawAdsRequired} to send a withdrawal request.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const NativeAdPlaceholder(),
              const SizedBox(height: 20),
              if (_shouldShowKeepMining(balance, minEth))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Keep mining! You need ${MiningConstants.formatEthFull((minEth! - balance).clamp(0.0, double.infinity))} ETH more to reach ~\$${MiningConstants.effectiveWithdrawThresholdUsd.toStringAsFixed(MiningConstants.withdrawTestMode ? 2 : 0)}.',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              AppTextField(label: 'Wallet Address', controller: _walletController),
              const SizedBox(height: 12),
              const Text(
                'Network',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedNetwork,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _networks.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedNetwork = v);
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: minEth != null ? 'Amount (min ${MiningConstants.formatEthFull(minEth)} ETH)' : 'Amount (ETH)',
                hint: '0.03 ETH',
                controller: _amountController,
              ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_loading || !canWithdraw) ? null : () => _onRequestWithdrawalPressed(balance),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Request Withdrawal'),
          ),
            ],
          );
        },
      ),
    );
  }
}

class _WithdrawAdsDialog extends StatelessWidget {
  const _WithdrawAdsDialog({
    required this.currentCount,
    required this.requiredCount,
    required this.onWatchAd,
    required this.onCancel,
  });

  final int currentCount;
  final int requiredCount;
  final VoidCallback onWatchAd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final complete = currentCount >= requiredCount;
    return AlertDialog(
      title: const Text('Withdrawal requirement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Watch $requiredCount rewarded ads to unlock withdrawal. Your progress is saved.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: complete ? 1.0 : currentCount / requiredCount,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    complete ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$currentCount / $requiredCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: complete ? null : onWatchAd,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(complete ? 'Done' : 'Watch ad'),
        ),
      ],
    );
  }
}
