import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/progress/providers/progress_providers.dart';
import 'package:mindfulness/widgets/warm_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final progress = ref.watch(progressSnapshotProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    progress.when(
                      data: (p) => _DayProgressRing(
                        streakDays: p.streakDays,
                        label: '${p.streakDays}',
                      ),
                      loading: () => const _DayProgressRing(
                        streakDays: 0,
                        label: '…',
                      ),
                      error: (_, __) => const _DayProgressRing(
                        streakDays: 0,
                        label: '—',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: text.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Today’s plan',
                            style: text.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 7,
                  itemBuilder: (context, i) {
                    final d = DateTime.now().subtract(Duration(days: 6 - i));
                    final isToday = i == 6;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _DateChip(date: d, selected: isToday),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Suggested for you',
                  style: text.titleMedium,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 132,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _PlanCard(
                      title: 'Focus session',
                      subtitle: 'Pomodoro · 25 min',
                      icon: Icons.timer_outlined,
                      gradient: const [Color(0xFFFFF3D6), Color(0xFFFFE4A8)],
                      onTap: () => context.go('/focus'),
                    ),
                    _PlanCard(
                      title: 'Meditate',
                      subtitle: 'Guided library',
                      icon: Icons.spa_outlined,
                      gradient: const [Color(0xFFE8F5F0), Color(0xFFD0EBE3)],
                      onTap: () => context.go('/meditations'),
                    ),
                    _PlanCard(
                      title: 'Breathe',
                      subtitle: 'Calm patterns',
                      icon: Icons.air_outlined,
                      gradient: const [Color(0xFFFFE8E0), Color(0xFFFFD4C4)],
                      onTap: () => context.go('/focus'),
                    ),
                    _PlanCard(
                      title: 'Progress',
                      subtitle: 'Streak & mood',
                      icon: Icons.insights_outlined,
                      gradient: const [Color(0xFFF0E8FF), Color(0xFFE4D4F7)],
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: WarmCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tip', style: text.titleSmall),
                      const SizedBox(height: 6),
                      Text(
                        'Small sessions count. Use the Breathing tab for a quick reset between focus blocks.',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _DayProgressRing extends StatelessWidget {
  const _DayProgressRing({
    required this.streakDays,
    required this.label,
  });

  final int streakDays;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pct = (streakDays.clamp(0, 7) / 7.0).clamp(0.0, 1.0);
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 5,
              backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.25),
              color: AppColors.accentCoral,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'streak',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.selected});

  final DateTime date;
  final bool selected;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final wd = _weekdays[date.weekday - 1];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? AppColors.primaryYellow
                : AppColors.surfaceCard,
            boxShadow: selected ? null : AppColors.cardShadow(context),
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.onPrimaryYellow
                        : AppColors.textPrimary,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          wd,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: Ink(
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              boxShadow: AppColors.cardShadow(context),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.85)),
                  const Spacer(),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
