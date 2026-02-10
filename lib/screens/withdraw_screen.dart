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

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _walletController = TextEditingController();
  final _networkController = TextEditingController(text: 'Ethereum');
  final _amountController = TextEditingController();
  bool _loading = false;
  double? _currentBalance;
  double? _ethPriceUsd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.tryShowInterstitialRandomly();
      _loadEthPrice();
    });
  }

  Future<void> _loadEthPrice() async {
    final price = await EthPriceService.instance.getCurrentPrice();
    if (mounted) setState(() => _ethPriceUsd = price);
  }

  @override
  void dispose() {
    _walletController.dispose();
    _networkController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? get _minEthForWithdraw {
    if (_ethPriceUsd == null || _ethPriceUsd! <= 0) return null;
    return MiningConstants.withdrawThresholdUsd / _ethPriceUsd!;
  }

  bool _canWithdraw(double balance) {
    if (_ethPriceUsd == null || _ethPriceUsd! <= 0) return false;
    return balance * _ethPriceUsd! >= MiningConstants.withdrawThresholdUsd;
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
                ? 'Minimum withdrawal is ~\$${MiningConstants.withdrawThresholdUsd.toStringAsFixed(0)} worth (${MiningConstants.formatEthFull(minEth)} ETH).'
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
      network: _networkController.text.trim(),
      amount: '$amountStr ETH',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _walletController.clear();
    _amountController.clear();
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
          _currentBalance = snap.data?.balanceBtc;
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
                    const Text(
                      'Withdraw ETH when balance is ~\$100 worth.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Balance: ${MiningConstants.formatEthFull(balance)} ETH${balanceUsd != null ? ' (≈ \$${balanceUsd.toStringAsFixed(2)})' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      minEth != null
                          ? 'Min. withdraw: ~\$${MiningConstants.withdrawThresholdUsd.toStringAsFixed(0)} (${MiningConstants.formatEthFull(minEth)} ETH)'
                          : 'Min. withdraw: ~\$100 worth of ETH',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const NativeAdPlaceholder(),
              const SizedBox(height: 20),
              if (!canWithdraw && minEth != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Keep mining! You need ${MiningConstants.formatEthFull((minEth - balance).clamp(0.0, double.infinity))} ETH more to reach ~\$100.',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              AppTextField(label: 'Wallet Address', controller: _walletController),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Network',
                hint: 'Ethereum',
                controller: _networkController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: minEth != null ? 'Amount (min ${MiningConstants.formatEthFull(minEth)} ETH)' : 'Amount (ETH)',
                hint: '0.03 ETH',
                controller: _amountController,
              ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_loading || !canWithdraw) ? null : _submit,
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
