import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/progress/domain/progress_math.dart';
import 'package:mindfulness/features/progress/providers/progress_providers.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

String _shortWeekday(DateTime d) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[d.weekday - 1];
}

String _formatDateTimeLocal(DateTime d) {
  final l = d.toLocal();
  final h = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '${l.month}/${l.day} $h:$min';
}

String fmtProgressMinutes(int seconds) {
  if (seconds <= 0) return '0';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m == 0) return '${s}s';
  if (s == 0) return '${m}m';
  return '${m}m ${s}s';
}

/// Streak, weekly chart, and mood sections — embedded in [ProfileScreen].
class ProgressOverviewContent extends ConsumerWidget {
  const ProgressOverviewContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(progressSnapshotProvider);
    final moodTrend = ref.watch(moodWeekTrendProvider);
    final moodsAsync = ref.watch(recentMoodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        progress.when(
          data: (p) => _StreakCard(streak: p.streakDays),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _RetryMessage(
            message: 'Could not load sessions.',
            detail: '$e',
            onRetry: () => ref.invalidate(recentSessionsProvider),
          ),
        ),
        const SizedBox(height: 16),
        progress.when(
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 26,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 28,
                      color: AppColors.accentCoral,
                    ),
                    const SizedBox(height: 10),
                    const SectionEyebrow('Total mindful minutes'),
                    const SizedBox(height: 8),
                    Text(
                      '${((p.totalFocusSecondsWeek + p.totalMindfulnessSecondsWeek) / 60).round()}',
                      style: text.headlineLarge?.copyWith(
                        color: AppColors.accentCoral,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This week across focus, meditation, and breathing.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionEyebrow('This week'),
                    const SizedBox(height: 8),
                    Text('Activity overview', style: text.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      '${fmtProgressMinutes(p.totalFocusSecondsWeek)} focus · '
                      '${fmtProgressMinutes(p.totalMindfulnessSecondsWeek)} mindfulness',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 220,
                      child: _WeeklyStackedChart(
                        week: p.week,
                        focusColor: AppColors.textBrand,
                        mindfulnessColor: AppColors.accentCoral,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChartLegend(
                      focusColor: AppColors.textBrand,
                      mindfulnessColor: AppColors.accentCoral,
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionEyebrow('Mood · last 7 days'),
              const SizedBox(height: 8),
              Text('Check-in trend', style: text.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Average after check-in, by day. Tap Log mood to add an entry.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: _MoodTrendRow(trend: moodTrend, scheme: scheme),
              ),
              const SizedBox(height: 20),
              moodsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Text(
                      'No mood entries yet.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  }
                  final preview = list.take(4).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent', style: text.titleSmall),
                      const SizedBox(height: 10),
                      for (final m in preview) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${m.moodAfter}',
                                  style: text.titleSmall?.copyWith(
                                    color: AppColors.textBrand,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m.moodBefore} → ${m.moodAfter}',
                                      style: text.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDateTimeLocal(m.createdAt),
                                      style: text.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => _RetryMessage(
                  message: 'Could not load moods.',
                  detail: '$e',
                  onRetry: () => ref.invalidate(recentMoodsProvider),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        children: [
          const SectionEyebrow('Current streak'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streak',
                style: text.headlineLarge?.copyWith(color: AppColors.textBrand),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  streak == 1 ? 'day' : 'days',
                  style: text.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index < streak.clamp(0, 5)
                      ? AppColors.textBrand
                      : AppColors.outlineMuted,
                  shape: BoxShape.circle,
                  boxShadow: index < streak.clamp(0, 5)
                      ? [
                          BoxShadow(
                            color: AppColors.primaryYellow.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStackedChart extends StatelessWidget {
  const _WeeklyStackedChart({
    required this.week,
    required this.focusColor,
    required this.mindfulnessColor,
  });

  final List<DayBucket> week;
  final Color focusColor;
  final Color mindfulnessColor;

  @override
  Widget build(BuildContext context) {
    final maxMin = week.fold<double>(1, (m, b) {
      final totalMin = b.totalSeconds / 60.0;
      return totalMin > m ? totalMin : m;
    });

    return BarChart(
      BarChartData(
        maxY: maxMin * 1.15,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= week.length) return const SizedBox.shrink();
                final d = week[i].day;
                final label = _shortWeekday(d);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < week.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                () {
                  final totalMin = week[i].totalSeconds / 60.0;
                  if (totalMin <= 0) {
                    return BarChartRodData(
                      width: 18,
                      toY: 0.08,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      rodStackItems: [
                        BarChartRodStackItem(
                          0,
                          0.08,
                          focusColor.withValues(alpha: 0.12),
                        ),
                      ],
                    );
                  }
                  return BarChartRodData(
                    width: 18,
                    toY: totalMin,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    rodStackItems: _stackItems(
                      week[i],
                      focusColor,
                      mindfulnessColor,
                    ),
                  );
                }(),
              ],
            ),
        ],
      ),
    );
  }

  List<BarChartRodStackItem> _stackItems(
    DayBucket bucket,
    Color focus,
    Color mind,
  ) {
    final fMin = bucket.focusSeconds / 60.0;
    final mMin = bucket.mindfulnessSeconds / 60.0;
    if (fMin <= 0 && mMin <= 0) {
      return [BarChartRodStackItem(0, 0.08, focus.withValues(alpha: 0.15))];
    }
    final items = <BarChartRodStackItem>[];
    var acc = 0.0;
    if (fMin > 0) {
      items.add(BarChartRodStackItem(acc, acc + fMin, focus));
      acc += fMin;
    }
    if (mMin > 0) {
      items.add(BarChartRodStackItem(acc, acc + mMin, mind));
    }
    if (items.isEmpty) {
      items.add(BarChartRodStackItem(0, 0.08, focus.withValues(alpha: 0.2)));
    }
    return items;
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.focusColor,
    required this.mindfulnessColor,
  });

  final Color focusColor;
  final Color mindfulnessColor;

  @override
  Widget build(BuildContext context) {
    Widget legend(String label, Color c) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );

    return Row(
      children: [
        legend('Focus', focusColor),
        const SizedBox(width: 20),
        legend('Mindfulness', mindfulnessColor),
      ],
    );
  }
}

class _MoodTrendRow extends StatelessWidget {
  const _MoodTrendRow({required this.trend, required this.scheme});

  final List<MoodDayTrend> trend;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < trend.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _MoodDayCell(t: trend[i], scheme: scheme),
          ),
        ],
      ],
    );
  }
}

class _MoodDayCell extends StatelessWidget {
  const _MoodDayCell({required this.t, required this.scheme});

  final MoodDayTrend t;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final h = t.count == 0 ? 8.0 : (t.avgAfter / 5.0 * 72).clamp(16.0, 72.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (t.count > 0)
          Text(
            t.avgAfter.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelSmall,
          )
        else
          Text('—', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Container(
          height: h,
          decoration: BoxDecoration(
            color: t.count == 0
                ? scheme.surfaceContainerHighest
                : scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _shortWeekday(t.day),
          style: Theme.of(context).textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
