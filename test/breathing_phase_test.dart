import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness/features/breathing/domain/breathing_preset.dart';

void main() {
  final box = BreathingPreset.defaults[0];

  test('resolveBreathingPhase starts in inhale', () {
    final s = resolveBreathingPhase(Duration.zero, box);
    expect(s.kind, BreathingPhaseKind.inhale);
    expect(s.phaseIndex, 0);
    expect(s.elapsedInPhase, Duration.zero);
  });

  test('resolveBreathingPhase advances through box cycle', () {
    expect(
      resolveBreathingPhase(const Duration(seconds: 3), box).kind,
      BreathingPhaseKind.inhale,
    );
    expect(
      resolveBreathingPhase(const Duration(seconds: 4), box).kind,
      BreathingPhaseKind.holdAfterInhale,
    );
    expect(
      resolveBreathingPhase(const Duration(seconds: 8), box).kind,
      BreathingPhaseKind.exhale,
    );
    expect(
      resolveBreathingPhase(const Duration(seconds: 12), box).kind,
      BreathingPhaseKind.holdAfterExhale,
    );
    final wrap = resolveBreathingPhase(const Duration(seconds: 16), box);
    expect(wrap.kind, BreathingPhaseKind.inhale);
    expect(wrap.phaseIndex, 0);
  });

  test('four-seven-eight has three phases', () {
    final p = BreathingPreset.defaults[2];
    expect(p.phases.length, 3);
    expect(
      resolveBreathingPhase(const Duration(seconds: 4), p).kind,
      BreathingPhaseKind.holdAfterInhale,
    );
    expect(
      resolveBreathingPhase(const Duration(seconds: 11), p).kind,
      BreathingPhaseKind.exhale,
    );
    final wrap = resolveBreathingPhase(const Duration(seconds: 19), p);
    expect(wrap.kind, BreathingPhaseKind.inhale);
  });

  test('breathingRingScale inhale end is expanded', () {
    expect(
      breathingRingScale(BreathingPhaseKind.inhale, 1),
      closeTo(1.0, 1e-6),
    );
    expect(
      breathingRingScale(BreathingPhaseKind.exhale, 1),
      closeTo(0.58, 1e-6),
    );
  });
}
