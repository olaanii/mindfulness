enum FocusLifecycle { idle, running, paused }

enum FocusSegment { work, shortBreak }

final class FocusTimerViewState {
  const FocusTimerViewState({
    required this.lifecycle,
    required this.segment,
    required this.remainingSeconds,
    required this.workLengthSec,
    required this.shortBreakLengthSec,
    required this.volume,
    required this.soundscapeEnabled,
  });

  factory FocusTimerViewState.initial() => FocusTimerViewState(
    lifecycle: FocusLifecycle.idle,
    segment: FocusSegment.work,
    remainingSeconds: _defaultWorkSec,
    workLengthSec: _defaultWorkSec,
    shortBreakLengthSec: _defaultBreakSec,
    volume: 0.35,
    soundscapeEnabled: false,
  );

  static const _defaultWorkSec = 25 * 60;
  static const _defaultBreakSec = 5 * 60;

  final FocusLifecycle lifecycle;
  final FocusSegment segment;
  final int remainingSeconds;
  final int workLengthSec;
  final int shortBreakLengthSec;
  final double volume;
  final bool soundscapeEnabled;

  FocusTimerViewState copyWith({
    FocusLifecycle? lifecycle,
    FocusSegment? segment,
    int? remainingSeconds,
    int? workLengthSec,
    int? shortBreakLengthSec,
    double? volume,
    bool? soundscapeEnabled,
  }) => FocusTimerViewState(
    lifecycle: lifecycle ?? this.lifecycle,
    segment: segment ?? this.segment,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    workLengthSec: workLengthSec ?? this.workLengthSec,
    shortBreakLengthSec: shortBreakLengthSec ?? this.shortBreakLengthSec,
    volume: volume ?? this.volume,
    soundscapeEnabled: soundscapeEnabled ?? this.soundscapeEnabled,
  );
}
