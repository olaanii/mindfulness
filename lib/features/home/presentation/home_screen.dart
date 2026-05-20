import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/progress/providers/progress_providers.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final user = ref.read(authServiceProvider).currentUser;
    final progress = ref.watch(progressSnapshotProvider);
    final streak = progress.asData?.value.streakDays ?? 0;
    final displayName = _displayName(user?.email);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: MindfulBackground(
        bottomPadding: 124,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            TopBlurBar(
              title: 'Mindfulness',
              trailing: UserAvatarBadge(
                email: user?.email,
                onTap: () => context.push('/account'),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_greeting()},', style: text.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: text.headlineLarge?.copyWith(
                          color: AppColors.textBrand,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _HomeStreakRing(
                  streakDays: streak,
                  label: progress.isLoading ? '…' : '$streak',
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionEyebrow('This week'),
                Text(
                  'Calendar',
                  style: text.labelMedium?.copyWith(
                    color: AppColors.accentCoral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = DateTime.now().subtract(
                    Duration(days: 6 - index),
                  );
                  return _WeekDayPill(date: date, selected: index == 6);
                },
              ),
            ),
            const SizedBox(height: 28),
            const SectionEyebrow('Daily reset'),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _ActionTile(
                        title: 'Focus',
                        subtitle: 'Pomodoro · 25 min',
                        icon: Icons.timer_outlined,
                        gradient: const [Color(0x26F5D547), Color(0x14F5D547)],
                        onTap: () => context.go('/focus'),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _ActionTile(
                        title: 'Meditate',
                        subtitle: 'Guided library',
                        icon: Icons.spa_outlined,
                        gradient: const [Color(0x189AC7B3), Color(0x0D9AC7B3)],
                        onTap: () => context.go('/meditations'),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _ActionTile(
                        title: 'Breathe',
                        subtitle: 'Calm patterns',
                        icon: Icons.air_rounded,
                        gradient: const [Color(0x1AFC9174), Color(0x0DFC9174)],
                        onTap: () => context.go('/focus'),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _ActionTile(
                        title: 'Progress',
                        subtitle: 'Streak & mood',
                        icon: Icons.insights_outlined,
                        gradient: const [Color(0x1A6F5D00), Color(0x087D7762)],
                        onTap: () => context.go('/profile'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            GlassPanel(
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryYellow.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.textBrand,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Insight', style: text.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Notice the pauses between your thoughts today. In those brief spaces of silence, true stillness resides.',
                              style: text.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _displayName(String? email) {
    if (email == null || email.isEmpty) return 'Friend';
    final handle = email.split('@').first.trim();
    if (handle.isEmpty) return 'Friend';
    return handle[0].toUpperCase() + handle.substring(1);
  }
}

class _HomeStreakRing extends StatelessWidget {
  const _HomeStreakRing({required this.streakDays, required this.label});

  final int streakDays;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = (streakDays.clamp(0, 14) / 14).clamp(0.0, 1.0);
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.18),
              color: AppColors.accentCoral,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: AppColors.accentCoral,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({required this.date, required this.selected});

  final DateTime date;
  final bool selected;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _letters[date.weekday - 1],
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          if (selected)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryYellow,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
              ),
            )
          else
            Text('${date.day}', style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(AppColors.radiusXl),
              ),
            ),
          ),
          SizedBox(
            height: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Icon(icon, color: AppColors.textPrimary),
                ),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
