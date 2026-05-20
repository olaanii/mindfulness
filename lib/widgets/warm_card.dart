import 'package:flutter/material.dart';
import 'package:mindfulness/core/theme/app_colors.dart';

/// Soft elevated surface (reference: low elevation + shadow).
class WarmCard extends StatelessWidget {
  const WarmCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glassPanel,
        border: Border.all(color: AppColors.glassBorder),
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: child,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        child: decorated,
      ),
    );
  }
}
