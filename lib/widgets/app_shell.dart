import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _NavSpec(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavSpec(Icons.spa_outlined, Icons.spa_rounded, 'Meditations'),
    _NavSpec(Icons.self_improvement_outlined, Icons.self_improvement, 'Breathing'),
    _NavSpec(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.iconOutlined),
              selectedIcon: Icon(d.iconSelected),
              label: d.label,
            ),
        ],
        onDestinationSelected: navigationShell.goBranch,
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.iconOutlined, this.iconSelected, this.label);

  final IconData iconOutlined;
  final IconData iconSelected;
  final String label;
}
