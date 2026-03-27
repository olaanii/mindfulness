import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness/features/focus_timer/domain/focus_timer_math.dart';

void main() {
  group('secondsRemainingUntilUtc', () {
    test('counts down to phase end', () {
      final end = DateTime.utc(2026, 3, 27, 12, 0, 30);
      final now = DateTime.utc(2026, 3, 27, 12, 0, 10);
      expect(secondsRemainingUntilUtc(now, end), 20);
    });

    test('returns zero when past deadline', () {
      final end = DateTime.utc(2026, 3, 27, 12, 0, 0);
      final now = DateTime.utc(2026, 3, 27, 12, 0, 5);
      expect(secondsRemainingUntilUtc(now, end), 0);
    });
  });
}
