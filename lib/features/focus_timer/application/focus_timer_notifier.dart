import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/core/notifications/notification_service.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/focus_timer/data/focus_sound_player.dart';
import 'package:mindfulness/features/focus_timer/data/focus_timer_prefs.dart';
import 'package:mindfulness/features/focus_timer/data/session_repository.dart';
import 'package:mindfulness/features/mood/providers/post_session_mood_provider.dart';
import 'package:mindfulness/features/focus_timer/domain/focus_timer_math.dart';
import 'package:mindfulness/features/focus_timer/domain/focus_timer_models.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Focus → short break flow; persists phase deadline for resume after background kill.
///
/// **iOS:** exact background countdown is limited; notification + deadline reconcile is the supported pattern.
/// **Android:** inexact alarm mode may delay notifications on aggressive OEM batteries.
final class FocusTimerNotifier extends Notifier<FocusTimerViewState> {
  Timer? _ticker;
  DateTime? _phaseEndUtc;
  FocusSoundPlayer? _audio;
  var _audioPrepared = false;

  @override
  FocusTimerViewState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      unawaited(_audio?.dispose() ?? Future<void>.value());
    });
    ref.listen(authStateProvider, (prev, next) {
      if (next.hasValue && next.value == null) {
        unawaited(_hardReset());
      }
    });
    Future.microtask(_bootstrap);
    return FocusTimerViewState.initial();
  }

  Future<void> _bootstrap() async {
    final m = await FocusTimerPrefs.load();
    if (m == null) return;
    final work = (m['workSec'] as num?)?.toInt() ??
        FocusTimerViewState.initial().workLengthSec;
    final breakSec = (m['breakSec'] as num?)?.toInt() ??
        FocusTimerViewState.initial().shortBreakLengthSec;
    final volume = (m['volume'] as num?)?.toDouble() ?? 0.35;
    final sound = m['soundscape'] as bool? ?? false;
    final lifecycle = FocusLifecycle.values.firstWhere(
      (e) => e.name == m['lifecycle'],
      orElse: () => FocusLifecycle.idle,
    );
    final segment = FocusSegment.values.firstWhere(
      (e) => e.name == m['segment'],
      orElse: () => FocusSegment.work,
    );
    final phaseEndMs = (m['phaseEndUtc'] as num?)?.toInt();
    final pausedRem = (m['pausedRemainingSec'] as num?)?.toInt();

    if (lifecycle == FocusLifecycle.idle) {
      state = FocusTimerViewState(
        lifecycle: FocusLifecycle.idle,
        segment: FocusSegment.work,
        remainingSeconds: work,
        workLengthSec: work,
        shortBreakLengthSec: breakSec,
        volume: volume,
        soundscapeEnabled: sound,
      );
      return;
    }

    if (lifecycle == FocusLifecycle.paused && pausedRem != null) {
      state = FocusTimerViewState(
        lifecycle: FocusLifecycle.paused,
        segment: segment,
        remainingSeconds: pausedRem,
        workLengthSec: work,
        shortBreakLengthSec: breakSec,
        volume: volume,
        soundscapeEnabled: sound,
      );
      return;
    }

    if (lifecycle == FocusLifecycle.running && phaseEndMs != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(phaseEndMs, isUtc: true);
      final now = DateTime.now().toUtc();
      final rem = secondsRemainingUntilUtc(now, end);
      if (rem <= 0) {
        await _recoverOverdue(
          segment: segment,
          workSec: work,
          breakSec: breakSec,
          volume: volume,
          sound: sound,
        );
        return;
      }
      _phaseEndUtc = end;
      state = FocusTimerViewState(
        lifecycle: FocusLifecycle.running,
        segment: segment,
        remainingSeconds: rem,
        workLengthSec: work,
        shortBreakLengthSec: breakSec,
        volume: volume,
        soundscapeEnabled: sound,
      );
      _startTicker();
      await WakelockPlus.enable();
      unawaited(
        NotificationService.instance.schedulePhaseEnd(
          whenLocal: end.toLocal(),
          title: segment == FocusSegment.work
              ? 'Focus round finished'
              : 'Break over',
          body: segment == FocusSegment.work
              ? 'Time for a short break.'
              : 'Ready for another focus round.',
        ),
      );
      if (sound && segment == FocusSegment.work) {
        await _ensureAudio();
        _audio!.setVolume(volume);
        await _audio!.play();
      }
    }
  }

  Future<void> _recoverOverdue({
    required FocusSegment segment,
    required int workSec,
    required int breakSec,
    required double volume,
    required bool sound,
  }) async {
    if (segment == FocusSegment.work) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        try {
          await ref.read(sessionRepositoryProvider).logFocusSession(
            userId: user.uid,
            durationSeconds: workSec,
          );
        } catch (_) {}
      }
      final now = DateTime.now().toUtc();
      _phaseEndUtc = now.add(Duration(seconds: breakSec));
      state = FocusTimerViewState(
        lifecycle: FocusLifecycle.running,
        segment: FocusSegment.shortBreak,
        remainingSeconds: breakSec,
        workLengthSec: workSec,
        shortBreakLengthSec: breakSec,
        volume: volume,
        soundscapeEnabled: sound,
      );
      await _persist();
      await NotificationService.instance.schedulePhaseEnd(
        whenLocal: _phaseEndUtc!.toLocal(),
        title: 'Focus round finished',
        body: 'Time for a short break.',
      );
      _startTicker();
      await WakelockPlus.enable();
      return;
    }

    await FocusTimerPrefs.clear();
    state = FocusTimerViewState(
      lifecycle: FocusLifecycle.idle,
      segment: FocusSegment.work,
      remainingSeconds: workSec,
      workLengthSec: workSec,
      shortBreakLengthSec: breakSec,
      volume: volume,
      soundscapeEnabled: sound,
    );
  }

  Future<void> _hardReset() async {
    ref.read(pendingFocusSessionMoodProvider.notifier).clear();
    _ticker?.cancel();
    _phaseEndUtc = null;
    await NotificationService.instance.cancelPhaseEnd();
    await FocusTimerPrefs.clear();
    await WakelockPlus.disable();
    await _audio?.stop();
    _audio = null;
    _audioPrepared = false;
    state = FocusTimerViewState.initial();
  }

  Future<void> start() async {
    if (state.lifecycle != FocusLifecycle.idle) return;
    await NotificationService.instance.requestPermissionsIfNeeded();
    final now = DateTime.now().toUtc();
    _phaseEndUtc = now.add(Duration(seconds: state.workLengthSec));
    state = state.copyWith(
      lifecycle: FocusLifecycle.running,
      segment: FocusSegment.work,
      remainingSeconds: state.workLengthSec,
    );
    await _persist();
    await NotificationService.instance.schedulePhaseEnd(
      whenLocal: _phaseEndUtc!.toLocal(),
      title: 'Focus round finished',
      body: 'Time for a short break.',
    );
    _startTicker();
    await WakelockPlus.enable();
    if (state.soundscapeEnabled) {
      await _ensureAudio();
      _audio!.setVolume(state.volume);
      await _audio!.play();
    }
  }

  Future<void> pause() async {
    if (state.lifecycle != FocusLifecycle.running) return;
    _ticker?.cancel();
    final rem = secondsRemainingUntilUtc(DateTime.now().toUtc(), _phaseEndUtc!);
    _phaseEndUtc = null;
    await NotificationService.instance.cancelPhaseEnd();
    state = state.copyWith(
      lifecycle: FocusLifecycle.paused,
      remainingSeconds: rem,
    );
    await _persist();
    await WakelockPlus.disable();
    await _audio?.pause();
  }

  Future<void> resume() async {
    if (state.lifecycle != FocusLifecycle.paused) return;
    final now = DateTime.now().toUtc();
    _phaseEndUtc = now.add(Duration(seconds: state.remainingSeconds));
    state = state.copyWith(lifecycle: FocusLifecycle.running);
    await _persist();
    final title = state.segment == FocusSegment.work
        ? 'Focus round finished'
        : 'Break over';
    final body = state.segment == FocusSegment.work
        ? 'Time for a short break.'
        : 'Ready for another focus round.';
    await NotificationService.instance.schedulePhaseEnd(
      whenLocal: _phaseEndUtc!.toLocal(),
      title: title,
      body: body,
    );
    _startTicker();
    await WakelockPlus.enable();
    if (state.soundscapeEnabled && state.segment == FocusSegment.work) {
      await _ensureAudio();
      _audio!.setVolume(state.volume);
      await _audio!.play();
    }
  }

  Future<void> reset() async {
    _ticker?.cancel();
    _phaseEndUtc = null;
    await NotificationService.instance.cancelPhaseEnd();
    await FocusTimerPrefs.clear();
    await WakelockPlus.disable();
    await _audio?.stop();
    final w = state.workLengthSec;
    final b = state.shortBreakLengthSec;
    final vol = state.volume;
    final snd = state.soundscapeEnabled;
    state = FocusTimerViewState(
      lifecycle: FocusLifecycle.idle,
      segment: FocusSegment.work,
      remainingSeconds: w,
      workLengthSec: w,
      shortBreakLengthSec: b,
      volume: vol,
      soundscapeEnabled: snd,
    );
  }

  void setWorkMinutes(int minutes) {
    if (state.lifecycle != FocusLifecycle.idle) return;
    final sec = minutes.clamp(5, 90) * 60;
    state = state.copyWith(
      workLengthSec: sec,
      remainingSeconds: sec,
    );
  }

  void setBreakMinutes(int minutes) {
    if (state.lifecycle != FocusLifecycle.idle) return;
    final sec = minutes.clamp(1, 30) * 60;
    state = state.copyWith(shortBreakLengthSec: sec);
  }

  Future<void> setVolume(double value) async {
    state = state.copyWith(volume: value);
    _audio?.setVolume(value);
    if (state.lifecycle != FocusLifecycle.idle) await _persist();
  }

  Future<void> setSoundscapeEnabled(bool enabled) async {
    state = state.copyWith(soundscapeEnabled: enabled);
    if (!enabled) {
      await _audio?.pause();
    } else if (state.lifecycle == FocusLifecycle.running &&
        state.segment == FocusSegment.work) {
      await _ensureAudio();
      _audio!.setVolume(state.volume);
      await _audio!.play();
    }
    if (state.lifecycle != FocusLifecycle.idle) await _persist();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _onTick();
  }

  void _onTick() {
    if (_phaseEndUtc == null || state.lifecycle != FocusLifecycle.running) {
      return;
    }
    final now = DateTime.now().toUtc();
    final rem = secondsRemainingUntilUtc(now, _phaseEndUtc!);
    if (rem != state.remainingSeconds) {
      state = state.copyWith(remainingSeconds: rem);
    }
    if (rem <= 0) {
      if (state.segment == FocusSegment.work) {
        unawaited(_onWorkComplete());
      } else {
        unawaited(_onBreakComplete());
      }
    }
  }

  Future<void> _onWorkComplete() async {
    _ticker?.cancel();
    await NotificationService.instance.cancelPhaseEnd();
    final workLen = state.workLengthSec;
    final breakLen = state.shortBreakLengthSec;
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        final sessionId = await ref.read(sessionRepositoryProvider).logFocusSession(
          userId: user.uid,
          durationSeconds: workLen,
        );
        ref.read(pendingFocusSessionMoodProvider.notifier).offer(sessionId);
      } catch (_) {}
    }
    final now = DateTime.now().toUtc();
    _phaseEndUtc = now.add(Duration(seconds: breakLen));
    state = state.copyWith(
      lifecycle: FocusLifecycle.running,
      segment: FocusSegment.shortBreak,
      remainingSeconds: breakLen,
    );
    await _persist();
    await NotificationService.instance.schedulePhaseEnd(
      whenLocal: _phaseEndUtc!.toLocal(),
      title: 'Break over',
      body: 'Ready for another focus round.',
    );
    _startTicker();
    await WakelockPlus.enable();
    await _audio?.pause();
  }

  Future<void> _onBreakComplete() async {
    _ticker?.cancel();
    await NotificationService.instance.cancelPhaseEnd();
    _phaseEndUtc = null;
    final w = state.workLengthSec;
    state = state.copyWith(
      lifecycle: FocusLifecycle.idle,
      segment: FocusSegment.work,
      remainingSeconds: w,
    );
    await FocusTimerPrefs.clear();
    await WakelockPlus.disable();
    await _audio?.stop();
  }

  Future<void> _persist() async {
    await FocusTimerPrefs.save({
      'v': 1,
      'workSec': state.workLengthSec,
      'breakSec': state.shortBreakLengthSec,
      'volume': state.volume,
      'soundscape': state.soundscapeEnabled,
      'lifecycle': state.lifecycle.name,
      'segment': state.segment.name,
      'phaseEndUtc': _phaseEndUtc?.millisecondsSinceEpoch,
      'pausedRemainingSec':
          state.lifecycle == FocusLifecycle.paused ? state.remainingSeconds : null,
    });
  }

  Future<void> _ensureAudio() async {
    _audio ??= FocusSoundPlayer();
    if (!_audioPrepared) {
      await _audio!.configureSession();
      await _audio!.prepare();
      _audioPrepared = true;
    }
  }
}
