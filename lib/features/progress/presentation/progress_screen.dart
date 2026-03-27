import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/progress/domain/progress_math.dart';
import 'package:mindfulness/features/progress/providers/progress_providers.dart';
import 'package:mindfulness/widgets/warm_card.dart';

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
        const SizedBox(height: 20),
        progress.when(
          data: (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This week', style: text.titleMedium),
              const SizedBox(height: 6),
              Text(
                '${fmtProgressMinutes(p.totalFocusSecondsWeek)} focus · '
                '${fmtProgressMinutes(p.totalMindfulnessSecondsWeek)} mindfulness '
                '(meditation + breathing)',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _WeeklyStackedChart(
                  week: p.week,
                  focusColor: scheme.primary,
                  mindfulnessColor: scheme.tertiary,
                ),
              ),
              const SizedBox(height: 8),
              _ChartLegend(
                focusColor: scheme.primary,
                mindfulnessColor: scheme.tertiary,
              ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 28),
        Text('Mood (last 7 days)', style: text.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Average after check-in, by day. Tap Log mood to add an entry.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: _MoodTrendRow(trend: moodTrend, scheme: scheme),
        ),
        const SizedBox(height: 16),
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
            final preview = list.take(5).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent', style: text.titleSmall),
                const SizedBox(height: 8),
                for (final m in preview)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${m.moodBefore} → ${m.moodAfter}',
                      style: text.titleSmall,
                    ),
                    subtitle: Text(_formatDateTimeLocal(m.createdAt)),
                  ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.error,
            ),
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
    return WarmCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            size: 40,
            color: AppColors.accentCoral,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak',
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                streak == 1 ? 'day streak' : 'days streak',
                style: text.titleSmall?.copyWith(
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
                    rodStackItems:
                        _stackItems(week[i], focusColor, mindfulnessColor),
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
