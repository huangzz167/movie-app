import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// 底部五 Tab：首页 / 搜索 / 历史 / 下载 / 我的
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(AppConstants.colorAccent);
    return NavigationBar(
      height: 64,
      selectedIndex: currentIndex,
      indicatorColor: accent.withOpacity(0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Text('🏠', style: TextStyle(fontSize: 22)),
          label: '首页',
        ),
        NavigationDestination(
          icon: Text('🔍', style: TextStyle(fontSize: 22)),
          label: '搜索',
        ),
        NavigationDestination(
          icon: Text('🕐', style: TextStyle(fontSize: 22)),
          label: '历史',
        ),
        NavigationDestination(
          icon: Text('⬇️', style: TextStyle(fontSize: 22)),
          label: '下载',
        ),
        NavigationDestination(
          icon: Text('👤', style: TextStyle(fontSize: 22)),
          label: '我的',
        ),
      ],
    );
  }
}
