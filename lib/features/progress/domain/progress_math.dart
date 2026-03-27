import 'package:mindfulness/core/models/session_log.dart';

DateTime dateOnlyLocal(DateTime dateTime) {
  final l = dateTime.toLocal();
  return DateTime(l.year, l.month, l.day);
}

/// Consecutive calendar days with any activity, anchored from today or yesterday.
int computeStreak(Set<DateTime> activityDaysLocal, DateTime todayLocal) {
  final today = dateOnlyLocal(todayLocal);
  final yesterday = today.subtract(const Duration(days: 1));
  late DateTime cursor;
  if (activityDaysLocal.contains(today)) {
    cursor = today;
  } else if (activityDaysLocal.contains(yesterday)) {
    cursor = yesterday;
  } else {
    return 0;
  }
  var streak = 0;
  while (activityDaysLocal.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

final class DayBucket {
  const DayBucket({
    required this.day,
    required this.focusSeconds,
    required this.meditationSeconds,
    required this.breathingSeconds,
  });

  final DateTime day;
  final int focusSeconds;
  final int meditationSeconds;
  final int breathingSeconds;

  int get mindfulnessSeconds => meditationSeconds + breathingSeconds;

  int get totalSeconds => focusSeconds + mindfulnessSeconds;
}

final class ProgressSnapshot {
  const ProgressSnapshot({
    required this.streakDays,
    required this.week,
    required this.totalFocusSecondsWeek,
    required this.totalMindfulnessSecondsWeek,
  });

  final int streakDays;
  /// Seven entries from oldest (index 0) to newest (index 6) in local calendar days.
  final List<DayBucket> week;
  final int totalFocusSecondsWeek;
  final int totalMindfulnessSecondsWeek;
}

ProgressSnapshot computeProgressSnapshot(
  List<SessionLog> sessions,
  DateTime nowLocal,
) {
  final today = dateOnlyLocal(nowLocal);
  final activityDays = <DateTime>{};
  for (final s in sessions) {
    activityDays.add(dateOnlyLocal(s.createdAt));
  }
  final streak = computeStreak(activityDays, today);

  final weekStart = today.subtract(const Duration(days: 6));
  final buckets = <DateTime, _Agg>{
    for (var i = 0; i < 7; i++)
      weekStart.add(Duration(days: i)): _Agg(),
  };

  for (final s in sessions) {
    final d = dateOnlyLocal(s.createdAt);
    final agg = buckets[d];
    if (agg == null) continue;
    switch (s.type) {
      case 'meditation':
        agg.meditation += s.durationSeconds;
        break;
      case 'breathing':
        agg.breathing += s.durationSeconds;
        break;
      case 'focus':
      default:
        agg.focus += s.durationSeconds;
        break;
    }
  }

  final week = List<DayBucket>.generate(7, (i) {
    final d = weekStart.add(Duration(days: i));
    final a = buckets[d]!;
    return DayBucket(
      day: d,
      focusSeconds: a.focus,
      meditationSeconds: a.meditation,
      breathingSeconds: a.breathing,
    );
  });

  var focusW = 0;
  var mindW = 0;
  for (final b in week) {
    focusW += b.focusSeconds;
    mindW += b.mindfulnessSeconds;
  }

  return ProgressSnapshot(
    streakDays: streak,
    week: week,
    totalFocusSecondsWeek: focusW,
    totalMindfulnessSecondsWeek: mindW,
  );
}

class _Agg {
  int focus = 0;
  int meditation = 0;
  int breathing = 0;
}
