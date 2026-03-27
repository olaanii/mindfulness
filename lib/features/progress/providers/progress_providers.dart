import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/focus_timer/data/session_repository.dart';
import 'package:mindfulness/features/mood/data/mood_repository.dart';
import 'package:mindfulness/features/mood/domain/mood_entry.dart';
import 'package:mindfulness/features/progress/domain/progress_math.dart';
import 'package:mindfulness/core/models/session_log.dart';

final recentSessionsProvider = StreamProvider<List<SessionLog>>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return Stream.value(const []);
  return ref.watch(sessionRepositoryProvider).watchSessions(userId: user.uid);
});

final progressSnapshotProvider = Provider<AsyncValue<ProgressSnapshot>>((ref) {
  final async = ref.watch(recentSessionsProvider);
  return async.when(
    data: (sessions) => AsyncData(
      computeProgressSnapshot(sessions, DateTime.now()),
    ),
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

final recentMoodsProvider = StreamProvider<List<MoodEntry>>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return Stream.value(const []);
  return ref.watch(moodRepositoryProvider).watchRecent(userId: user.uid);
});

/// Per local calendar day over the last 7 days: average `moodAfter` (0 if none).
final moodWeekTrendProvider = Provider<List<MoodDayTrend>>((ref) {
  final async = ref.watch(recentMoodsProvider);
  return async.maybeWhen(
    data: (entries) => computeMoodWeekTrend(entries, DateTime.now()),
    orElse: () => const [],
  );
});

final class MoodDayTrend {
  const MoodDayTrend({
    required this.day,
    required this.avgAfter,
    required this.count,
  });

  final DateTime day;
  final double avgAfter;
  final int count;
}

List<MoodDayTrend> computeMoodWeekTrend(
  List<MoodEntry> entries,
  DateTime nowLocal,
) {
  final today = dateOnlyLocal(nowLocal);
  final start = today.subtract(const Duration(days: 6));
  final byDay = <DateTime, List<int>>{
    for (var i = 0; i < 7; i++) start.add(Duration(days: i)): [],
  };
  for (final e in entries) {
    final d = dateOnlyLocal(e.createdAt);
    final list = byDay[d];
    if (list != null) list.add(e.moodAfter);
  }
  return List.generate(7, (i) {
    final d = start.add(Duration(days: i));
    final vals = byDay[d]!;
    if (vals.isEmpty) {
      return MoodDayTrend(day: d, avgAfter: 0, count: 0);
    }
    final sum = vals.fold<int>(0, (a, b) => a + b);
    return MoodDayTrend(
      day: d,
      avgAfter: sum / vals.length,
      count: vals.length,
    );
  });
}
