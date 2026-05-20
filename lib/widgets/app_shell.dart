import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _NavSpec(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavSpec(Icons.spa_outlined, Icons.spa_rounded, 'Meditations'),
    _NavSpec(Icons.self_improvement_outlined, Icons.self_improvement, 'Focus'),
    _NavSpec(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusXl),
            bottom: Radius.circular(24),
          ),
          color: AppColors.headerGlass.withValues(alpha: 0.92),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < _destinations.length; i++)
                Expanded(
                  child: _ShellNavItem(
                    spec: _destinations[i],
                    selected: navigationShell.currentIndex == i,
                    onTap: () => navigationShell.goBranch(
                      i,
                      initialLocation: i == _destinations.length - 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? spec.iconSelected : spec.iconOutlined;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: selected ? AppColors.textBrand : AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? AppColors.elevatedGlow(context) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.textBrand : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                spec.label,
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
