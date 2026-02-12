import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_gradients.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/user_avatar.dart';
import 'dashboard_screen.dart';
import 'farm_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'transactions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const int _shopTabIndex = 2;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      FarmScreen(onOpenShop: () => setState(() => _index = _shopTabIndex)),
      const ShopScreen(),
      const TransactionsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 48,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.eth,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'GIGA LTC',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          _MiningBadge(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              borderRadius: BorderRadius.circular(20),
              child: const UserAvatar(size: 34),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _buildNavItem(icon: Icons.dashboard_rounded, label: 'Home', index: 0),
                _buildNavItem(icon: Icons.factory_rounded, label: 'Farm', index: 1),
                _buildNavItem(icon: Icons.shopping_bag_rounded, label: 'Shop', index: 2),
                _buildNavItem(icon: Icons.receipt_long_rounded, label: 'History', index: 3),
                _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AdService.instance.tryShowInterstitialRandomly();
          setState(() => _index = index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiningBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<Map<String, dynamic>>(
      stream: DatabaseService.instance.miningStream(user.uid),
      builder: (context, snapshot) {
        final active = snapshot.data?['active'] == true;
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.primary.withOpacity(0.4) : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                width: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                active ? 'Live' : 'Paused',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}