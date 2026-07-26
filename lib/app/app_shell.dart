import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liangzhi/shared/design/app_icons.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(AppIcons.home),
            selectedIcon: Icon(AppIcons.homeSelected),
            label: '首页',
            tooltip: '首页',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.expirations),
            selectedIcon: Icon(AppIcons.expirationsSelected),
            label: '到期提醒',
            tooltip: '到期提醒',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.scan),
            selectedIcon: Icon(AppIcons.scan),
            label: '扫码添加',
            tooltip: '扫码添加',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.foods),
            selectedIcon: Icon(AppIcons.foodsSelected),
            label: '全部食物',
            tooltip: '全部食物',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.mine),
            selectedIcon: Icon(AppIcons.mineSelected),
            label: '我的',
            tooltip: '我的',
          ),
        ],
      ),
    );
  }
}
