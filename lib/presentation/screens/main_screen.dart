import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../providers/game_provider.dart';
import 'home_screen.dart';
import 'prestige_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';
import 'upgrade_screen.dart';

/// 5개 탭의 하단 네비게이션 + IndexedStack 구조 (sw_clicker 매핑).
///
/// 탭 구성:
///   0. 광산 (홈) — 광맥 탭으로 채굴 + 인벤토리
///   1. 강화      — 터치/동료/곡괭이
///   2. 상점      — 도감/조수/광맥 정수
///   3. 환생      — 별의 의식 + 5 영구 트리
///   4. 설정      — 자동환전/디버그/정보
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    UpgradeScreen(),
    StoreScreen(),
    PrestigeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: AppColors.deepShaft,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.cardBackground,
          indicatorColor: AppColors.gold.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 62,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.gold),
              label: '광산',
            ),
            const NavigationDestination(
              icon: Icon(Icons.upgrade_outlined,
                  color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.upgrade_rounded, color: AppColors.gold),
              label: '강화',
            ),
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined,
                  color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.storefront, color: AppColors.gold),
              label: '상점',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.auto_awesome_outlined,
                color: game.canRebirthNow
                    ? AppColors.gold
                    : AppColors.textSecondary,
              ),
              selectedIcon:
                  const Icon(Icons.auto_awesome, color: AppColors.gold),
              label: '환생',
            ),
            const NavigationDestination(
              icon: Icon(Icons.tune_outlined,
                  color: AppColors.textSecondary),
              selectedIcon:
                  Icon(Icons.tune_rounded, color: AppColors.gold),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
