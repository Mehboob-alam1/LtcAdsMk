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

  List<Widget> get _screens => [
    const DashboardScreen(),
    FarmScreen(onOpenShop: () => setState(() => _index = _shopTabIndex)),
    const ShopScreen(),
    const TransactionsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                border: Border.all(color: AppColors.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(
                Icons.menu_rounded,
                size: 22,
              ),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppGradients.eth,
                borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'GIGA ETH',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          _MiningBadge(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const UserAvatar(size: 36),
            ),
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  color: const Color(0xFF1466FF),
                ),
                _buildNavItem(
                  icon: Icons.factory_rounded,
                  label: 'Farm',
                  index: 1,
                  color: const Color(0xFF1CB36B),
                ),
                _buildNavItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Shop',
                  index: 2,
                  color: AppColors.primary,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'History',
                  index: 3,
                  color: AppColors.primary,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 4,
                  color: AppColors.primary,
                ),
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
    required Color color,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? color : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey.shade500,
                ),
                child: Text(label),
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
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? [
                const Color(0xFFE5FFF1),
                const Color(0xFFD0FFE5),
              ]
                  : [
                const Color(0xFFFFE8E8),
                const Color(0xFFFFD6D6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? const Color(0xFF1CB36B).withOpacity(0.3)
                  : const Color(0xFFE75A5A).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? const Color(0xFF1CB36B).withOpacity(0.2)
                    : const Color(0xFFE75A5A).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color:
                  active ? const Color(0xFF1CB36B) : const Color(0xFFE75A5A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: active
                          ? const Color(0xFF1CB36B).withOpacity(0.5)
                          : const Color(0xFFE75A5A).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                active ? 'Mining' : 'Paused',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: active ? const Color(0xFF0F8A4F) : const Color(0xFFD04848),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}