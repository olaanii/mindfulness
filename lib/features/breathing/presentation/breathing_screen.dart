import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/breathing/domain/breathing_preset.dart';
import 'package:mindfulness/features/focus_timer/data/session_repository.dart';
import 'package:mindfulness/features/mood/presentation/mood_check_in_sheet.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

/// Breathing cycles are driven by wall-clock elapsed time ([_WallClockSession])
/// plus a single [Ticker] for repaints only, keeping phase boundaries stable.
class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key, this.embedded = false});

  /// When true, omits [Scaffold] / [AppBar] for use inside [TabBarView].
  final bool embedded;

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _WallClockSession {
  Duration _offset = Duration.zero;
  DateTime? _runStart;

  bool get isRunning => _runStart != null;

  Duration get elapsed {
    if (_runStart == null) return _offset;
    return _offset + DateTime.now().difference(_runStart!);
  }

  void start() {
    _runStart ??= DateTime.now();
  }

  void pause() {
    if (_runStart == null) return;
    _offset += DateTime.now().difference(_runStart!);
    _runStart = null;
  }

  void resume() {
    start();
  }

  void stop() {
    _offset = Duration.zero;
    _runStart = null;
  }
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  BreathingPreset _preset = BreathingPreset.defaults.first;
  final _WallClockSession _session = _WallClockSession();
  late Ticker _ticker;
  int _lastPhaseIndex = -1;
  bool _phaseSoundEnabled = true;
  final Duration _targetDuration = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (_session.isRunning) {
        _checkPhaseSound();
        setState(() {});
      }
    });
  }

  void _checkPhaseSound() {
    final snap = resolveBreathingPhase(_session.elapsed, _preset);
    if (snap.phaseIndex != _lastPhaseIndex) {
      if (_phaseSoundEnabled && _lastPhaseIndex >= 0) {
        SystemSound.play(SystemSoundType.click);
      }
      _lastPhaseIndex = snap.phaseIndex;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onStart() {
    setState(() {
      _session.start();
      _lastPhaseIndex = -1;
      _ticker.start();
    });
  }

  void _onPause() {
    setState(() {
      _session.pause();
      if (!_session.isRunning && _session.elapsed == Duration.zero) {
        _lastPhaseIndex = -1;
        _ticker.stop();
      } else if (!_session.isRunning) {
        _ticker.stop();
      }
    });
  }

  void _onResume() {
    setState(() {
      _session.resume();
      _lastPhaseIndex = resolveBreathingPhase(
        _session.elapsed,
        _preset,
      ).phaseIndex;
      _ticker.start();
    });
  }

  void _onStop() {
    final elapsed = _session.elapsed;
    final hadTime = _session.isRunning || elapsed > Duration.zero;
    setState(() {
      _session.stop();
      _lastPhaseIndex = -1;
      _ticker.stop();
    });
    if (hadTime && elapsed.inSeconds >= 15) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        unawaited(_logBreathingAndOfferMood(user.uid, elapsed.inSeconds));
      }
    }
  }

  Future<void> _logBreathingAndOfferMood(String userId, int seconds) async {
    try {
      final id = await ref
          .read(sessionRepositoryProvider)
          .logBreathingSession(userId: userId, durationSeconds: seconds);
      if (mounted) {
        await showMoodCheckInSheet(context, ref, sessionId: id);
      }
    } catch (_) {}
  }

  void _setPreset(BreathingPreset preset) {
    setState(() {
      _preset = preset;
      _session.stop();
      _lastPhaseIndex = -1;
      _ticker.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = resolveBreathingPhase(_session.elapsed, _preset);
    final scale = breathingRingScale(snapshot.kind, snapshot.phaseProgress);
    final remaining = snapshot.phaseDuration - snapshot.elapsedInPhase;
    final remainingSecs = remaining.inMilliseconds <= 0
        ? 0
        : (remaining.inMilliseconds + 999) ~/ 1000;
    final elapsedSeconds = _session.elapsed.inSeconds;
    final durationProgress =
        (_targetDuration.inSeconds == 0
                ? 0.0
                : elapsedSeconds / _targetDuration.inSeconds)
            .clamp(0.0, 1.0);
    final title = _preset.id == 'box_4444'
        ? 'Box Breathing'
        : _preset.id == 'four_seven_eight'
        ? '4-7-8 Relax'
        : 'Deep Calm';
    final subtitle = _preset.phases
        .map(
          (phase) =>
              '${phase.duration.inSeconds}s ${_phaseShortLabel(phase.kind)}',
        )
        .join(' • ');
    final primaryIcon = _session.isRunning
        ? Icons.pause_rounded
        : (_session.elapsed > Duration.zero
              ? Icons.play_arrow_rounded
              : Icons.play_arrow_rounded);

    final inner = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 34),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final ringSize = constraints.maxHeight
                      .clamp(108.0, 250.0)
                      .toDouble();
                  final glowSize = (ringSize * 1.25)
                      .clamp(ringSize, 312.0)
                      .toDouble();
                  final coreSize = (ringSize * 0.6)
                      .clamp(88.0, 150.0)
                      .toDouble();
                  final phaseLabelStyle =
                      (ringSize < 150
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleLarge)
                          ?.copyWith(color: AppColors.textBrand);
                  final countdownStyle =
                      (ringSize < 150
                              ? Theme.of(context).textTheme.headlineMedium
                              : Theme.of(context).textTheme.displaySmall)
                          ?.copyWith(
                            color: AppColors.textBrand,
                            fontWeight: FontWeight.w800,
                          );

                  return Center(
                    child: Semantics(
                      label:
                          '${_phaseDisplayLabel(snapshot.kind)}, about $remainingSecs seconds left in phase',
                      child: AnimatedScale(
                        scale: scale,
                        duration: Duration.zero,
                        child: SizedBox(
                          width: ringSize,
                          height: ringSize,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              IgnorePointer(
                                child: Container(
                                  width: glowSize,
                                  height: glowSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.primaryYellow.withValues(
                                          alpha: 0.20,
                                        ),
                                        AppColors.primaryYellow.withValues(
                                          alpha: 0.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                painter: _BreathingRingPainter(
                                  color: AppColors.primaryYellow,
                                ),
                                size: Size.square(ringSize),
                                child: Container(
                                  width: coreSize,
                                  height: coreSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryYellow.withValues(
                                      alpha: 0.40,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryYellow
                                            .withValues(alpha: 0.30),
                                        blurRadius: ringSize < 150 ? 24 : 40,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _phaseDisplayLabel(snapshot.kind),
                                        style: phaseLabelStyle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$remainingSecs',
                                        style: countdownStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            GlassPanel(
              padding: const EdgeInsets.all(25),
              color: AppColors.headerGlass.withValues(alpha: 0.42),
              borderColor: AppColors.borderSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duration',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatClock(_targetDuration),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: AppColors.textBrand),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: durationProgress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE9E2D3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BreathingControlButton(
                        icon: _phaseSoundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        size: 48,
                        onTap: () => setState(
                          () => _phaseSoundEnabled = !_phaseSoundEnabled,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _BreathingControlButton(
                        icon: primaryIcon,
                        size: 64,
                        primary: true,
                        onTap: _session.isRunning
                            ? _onPause
                            : (_session.elapsed > Duration.zero
                                  ? _onResume
                                  : _onStart),
                      ),
                      const SizedBox(width: 24),
                      _BreathingControlButton(
                        icon: Icons.tune_rounded,
                        size: 48,
                        onTap:
                            (_session.isRunning ||
                                _session.elapsed > Duration.zero)
                            ? _onStop
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: BreathingPreset.defaults.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final preset = BreathingPreset.defaults[index];
                  return MindfulPill(
                    label: _presetChipLabel(preset),
                    selected: preset.id == _preset.id,
                    onTap: _session.isRunning ? null : () => _setPreset(preset),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) return inner;

    return Scaffold(
      appBar: AppBar(title: const Text('Breathing')),
      body: inner,
    );
  }
}

class _BreathingRingPainter extends CustomPainter {
  _BreathingRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(c, r - 2, fillPaint);
    canvas.drawCircle(c, r - 2, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _BreathingRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

String _phaseDisplayLabel(BreathingPhaseKind kind) {
  return switch (kind) {
    BreathingPhaseKind.inhale => 'Breathe In',
    BreathingPhaseKind.holdAfterInhale => 'Hold',
    BreathingPhaseKind.exhale => 'Breathe Out',
    BreathingPhaseKind.holdAfterExhale => 'Hold',
  };
}

String _phaseShortLabel(BreathingPhaseKind kind) {
  return switch (kind) {
    BreathingPhaseKind.inhale => 'In',
    BreathingPhaseKind.holdAfterInhale => 'Hold',
    BreathingPhaseKind.exhale => 'Out',
    BreathingPhaseKind.holdAfterExhale => 'Hold',
  };
}

String _presetChipLabel(BreathingPreset preset) {
  return switch (preset.id) {
    'box_4444' => 'Box Breathing',
    'four_seven_eight' => '4-7-8 Relax',
    _ => 'Deep Calm',
  };
}

String _formatClock(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(1, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _BreathingControlButton extends StatelessWidget {
  const _BreathingControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: primary ? AppColors.textBrand : AppColors.surfaceMuted,
            shape: BoxShape.circle,
            boxShadow: primary ? AppColors.cardShadow(context) : null,
          ),
          child: Icon(
            icon,
            size: primary ? 30 : 24,
            color: primary ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
