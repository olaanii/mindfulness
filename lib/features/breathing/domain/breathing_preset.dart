import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

enum BreathingPhaseKind {
  inhale,
  holdAfterInhale,
  exhale,
  holdAfterExhale,
}

@immutable
class BreathingPhaseStep {
  const BreathingPhaseStep(this.kind, this.duration);

  final BreathingPhaseKind kind;
  final Duration duration;
}

@immutable
class BreathingPreset {
  const BreathingPreset({
    required this.id,
    required this.label,
    required this.phases,
  });

  final String id;
  final String label;
  final List<BreathingPhaseStep> phases;

  Duration get cycleDuration {
    var total = Duration.zero;
    for (final p in phases) {
      total += p.duration;
    }
    return total;
  }

  static const List<BreathingPreset> defaults = [
    BreathingPreset(
      id: 'box_4444',
      label: 'Box 4-4-4-4',
      phases: [
        BreathingPhaseStep(BreathingPhaseKind.inhale, Duration(seconds: 4)),
        BreathingPhaseStep(
          BreathingPhaseKind.holdAfterInhale,
          Duration(seconds: 4),
        ),
        BreathingPhaseStep(BreathingPhaseKind.exhale, Duration(seconds: 4)),
        BreathingPhaseStep(
          BreathingPhaseKind.holdAfterExhale,
          Duration(seconds: 4),
        ),
      ],
    ),
    BreathingPreset(
      id: 'relax_466',
      label: 'Relax 4-6-6',
      phases: [
        BreathingPhaseStep(BreathingPhaseKind.inhale, Duration(seconds: 4)),
        BreathingPhaseStep(
          BreathingPhaseKind.holdAfterInhale,
          Duration(seconds: 6),
        ),
        BreathingPhaseStep(BreathingPhaseKind.exhale, Duration(seconds: 6)),
        BreathingPhaseStep(
          BreathingPhaseKind.holdAfterExhale,
          Duration(seconds: 2),
        ),
      ],
    ),
    BreathingPreset(
      id: 'four_seven_eight',
      label: '4-7-8',
      phases: [
        BreathingPhaseStep(BreathingPhaseKind.inhale, Duration(seconds: 4)),
        BreathingPhaseStep(
          BreathingPhaseKind.holdAfterInhale,
          Duration(seconds: 7),
        ),
        BreathingPhaseStep(BreathingPhaseKind.exhale, Duration(seconds: 8)),
      ],
    ),
  ];
}

@immutable
class BreathingPhaseSnapshot {
  const BreathingPhaseSnapshot({
    required this.phaseIndex,
    required this.kind,
    required this.elapsedInPhase,
    required this.phaseDuration,
  });

  final int phaseIndex;
  final BreathingPhaseKind kind;
  final Duration elapsedInPhase;
  final Duration phaseDuration;

  double get phaseProgress {
    if (phaseDuration.inMilliseconds <= 0) return 0;
    return (elapsedInPhase.inMilliseconds / phaseDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }
}

/// Maps total elapsed time into the current phase. Uses a single wall-clock
/// [elapsed] from the session so phase boundaries stay aligned over long runs.
BreathingPhaseSnapshot resolveBreathingPhase(
  Duration elapsed,
  BreathingPreset preset,
) {
  final cycleMs = preset.cycleDuration.inMilliseconds;
  if (cycleMs <= 0) {
    return const BreathingPhaseSnapshot(
      phaseIndex: 0,
      kind: BreathingPhaseKind.inhale,
      elapsedInPhase: Duration.zero,
      phaseDuration: Duration(seconds: 1),
    );
  }
  var ms = elapsed.inMilliseconds % cycleMs;
  var acc = 0;
  for (var i = 0; i < preset.phases.length; i++) {
    final step = preset.phases[i];
    final d = step.duration.inMilliseconds;
    if (d <= 0) continue;
    final end = acc + d;
    if (ms < end) {
      return BreathingPhaseSnapshot(
        phaseIndex: i,
        kind: step.kind,
        elapsedInPhase: Duration(
          milliseconds: (ms - acc).clamp(0, d),
        ),
        phaseDuration: step.duration,
      );
    }
    acc = end;
  }
  final last = preset.phases.isEmpty
      ? const BreathingPhaseStep(
          BreathingPhaseKind.inhale,
          Duration(seconds: 1),
        )
      : preset.phases.last;
  return BreathingPhaseSnapshot(
    phaseIndex: preset.phases.isEmpty ? 0 : preset.phases.length - 1,
    kind: last.kind,
    elapsedInPhase: Duration.zero,
    phaseDuration: last.duration,
  );
}

String breathingPhaseLabel(BreathingPhaseKind kind) {
  return switch (kind) {
    BreathingPhaseKind.inhale => 'Inhale',
    BreathingPhaseKind.holdAfterInhale => 'Hold',
    BreathingPhaseKind.exhale => 'Exhale',
    BreathingPhaseKind.holdAfterExhale => 'Hold',
  };
}

/// Visual scale for the ring: inhale expands, exhale contracts, holds fixed.
double breathingRingScale(BreathingPhaseKind kind, double t) {
  const minS = 0.58;
  const maxS = 1.0;
  return switch (kind) {
    BreathingPhaseKind.inhale => lerpDouble(minS, maxS, t)!,
    BreathingPhaseKind.holdAfterInhale => maxS,
    BreathingPhaseKind.exhale => lerpDouble(maxS, minS, t)!,
    BreathingPhaseKind.holdAfterExhale => minS,
  };
}
