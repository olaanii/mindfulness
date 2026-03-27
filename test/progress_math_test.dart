import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness/core/models/session_log.dart';
import 'package:mindfulness/features/progress/domain/progress_math.dart';

SessionLog _log(String type, DateTime at, {int sec = 60}) {
  return SessionLog(
    id: 'x_${type}_${at.millisecondsSinceEpoch}',
    userId: 'u1',
    type: type,
    durationSeconds: sec,
    createdAt: at,
  );
}

void main() {
  group('computeStreak', () {
    test('returns 0 when no activity today or yesterday', () {
      final today = DateTime(2026, 3, 27);
      expect(computeStreak({}, today), 0);
      expect(
        computeStreak({DateTime(2026, 3, 24)}, today),
        0,
      );
    });

    test('counts consecutive days ending today', () {
      final today = DateTime(2026, 3, 27);
      final days = {
        DateTime(2026, 3, 25),
        DateTime(2026, 3, 26),
        DateTime(2026, 3, 27),
      };
      expect(computeStreak(days, today), 3);
    });

    test('allows streak ending yesterday if today is empty', () {
      final today = DateTime(2026, 3, 27);
      final days = {
        DateTime(2026, 3, 25),
        DateTime(2026, 3, 26),
      };
      expect(computeStreak(days, today), 2);
    });
  });

  group('computeProgressSnapshot', () {
    test('aggregates focus vs mindfulness for current week', () {
      final now = DateTime(2026, 3, 27, 15);
      final weekStart = DateTime(2026, 3, 21);
      final day2 = weekStart.add(const Duration(days: 1));
      final sessions = [
        _log('focus', weekStart, sec: 300),
        _log('meditation', day2, sec: 600),
        _log('breathing', day2, sec: 120),
        _log('focus', now, sec: 120),
      ];
      final snap = computeProgressSnapshot(sessions, now);
      expect(snap.streakDays, greaterThanOrEqualTo(1));
      expect(snap.week.last.focusSeconds, 120);
      expect(snap.week.first.focusSeconds, 300);
      final mindBucket = snap.week.firstWhere((b) => b.mindfulnessSeconds == 720);
      expect(mindBucket.meditationSeconds, 600);
      expect(mindBucket.breathingSeconds, 120);
      expect(snap.totalFocusSecondsWeek, 300 + 120);
      expect(snap.totalMindfulnessSecondsWeek, 600 + 120);
    });
  });
}
