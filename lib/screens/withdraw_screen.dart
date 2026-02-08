import 'package:flutter/material.dart';

import '../constants/mining_constants.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
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
  final _networkController = TextEditingController(text: 'Bitcoin');
  final _amountController = TextEditingController();
  bool _loading = false;
  double? _currentBalance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.tryShowInterstitialRandomly();
    });
  }

  @override
  void dispose() {
    _walletController.dispose();
    _networkController.dispose();
    _amountController.dispose();
    super.dispose();
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
    final amountStr = _amountController.text.trim().replaceAll(RegExp(r'\s*BTC\s*', caseSensitive: false), '').trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount < MiningConstants.minWithdrawBtc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum withdrawal is ${MiningConstants.formatBtcFull(MiningConstants.minWithdrawBtc)} BTC.',
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
      amount: '$amountStr BTC',
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
        backgroundColor: const Color(0xFFF9F4F7),
      ),
      body: StreamBuilder(
        stream: AuthService.instance.currentUser != null
            ? DatabaseService.instance.statsStream(AuthService.instance.currentUser!.uid)
            : null,
        builder: (context, snap) {
          _currentBalance = snap.data?.balanceBtc;
          final balance = _currentBalance ?? 0.0;
          final canWithdraw = balance >= MiningConstants.minWithdrawBtc;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppGradients.btc,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Withdraw BTC to your wallet securely.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Balance: ${MiningConstants.formatBtcFull(balance)} BTC',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      'Min. withdraw: ${MiningConstants.formatBtcFull(MiningConstants.minWithdrawBtc)} BTC',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const NativeAdPlaceholder(),
              const SizedBox(height: 20),
              if (!canWithdraw)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Keep mining! You need ${MiningConstants.formatBtcFull(MiningConstants.minWithdrawBtc - balance)} BTC more to withdraw.',
                    style: const TextStyle(color: Color(0xFFB14FC7), fontWeight: FontWeight.w600),
                  ),
                ),
              AppTextField(label: 'Wallet Address', controller: _walletController),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Network',
                hint: 'Bitcoin',
                controller: _networkController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Amount (min ${MiningConstants.formatBtcFull(MiningConstants.minWithdrawBtc)} BTC)',
                hint: '0.00001500 BTC',
                controller: _amountController,
              ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (_loading || !canWithdraw) ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB14FC7),
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
