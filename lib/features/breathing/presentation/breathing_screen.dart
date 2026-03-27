import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/breathing/domain/breathing_preset.dart';
import 'package:mindfulness/features/focus_timer/data/session_repository.dart';
import 'package:mindfulness/features/mood/presentation/mood_check_in_sheet.dart';

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
      if (_lastPhaseIndex >= 0) {
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
      _lastPhaseIndex =
          resolveBreathingPhase(_session.elapsed, _preset).phaseIndex;
      _ticker.start();
    });
  }

  void _onStop() {
    final elapsed = _session.elapsed;
    final hadTime =
        _session.isRunning || elapsed > Duration.zero;
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
      final id = await ref.read(sessionRepositoryProvider).logBreathingSession(
        userId: userId,
        durationSeconds: seconds,
      );
      if (mounted) {
        await showMoodCheckInSheet(context, ref, sessionId: id);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final snapshot = resolveBreathingPhase(_session.elapsed, _preset);
    final scale = breathingRingScale(snapshot.kind, snapshot.phaseProgress);
    final remaining = snapshot.phaseDuration - snapshot.elapsedInPhase;
    final remainingSecs = remaining.inMilliseconds <= 0
        ? 0
        : (remaining.inMilliseconds + 999) ~/ 1000;

    final inner = SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose a pattern',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in BreathingPreset.defaults)
                    ChoiceChip(
                      label: Text(p.label),
                      selected: p.id == _preset.id,
                      onSelected: _session.isRunning
                          ? null
                          : (v) {
                              if (v) {
                                setState(() {
                                  _preset = p;
                                  _session.stop();
                                  _lastPhaseIndex = -1;
                                  _ticker.stop();
                                });
                              }
                            },
                    ),
                ],
              ),
              const Spacer(),
              Center(
                child: Semantics(
                  label:
                      '${breathingPhaseLabel(snapshot.kind)}, '
                      'about $remainingSecs seconds left in phase',
                  child: AnimatedScale(
                    scale: scale,
                    duration: Duration.zero,
                    child: CustomPaint(
                      painter: _BreathingRingPainter(color: cs.primary),
                      size: const Size.square(220),
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                breathingPhaseLabel(snapshot.kind),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${remainingSecs}s',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (!_session.isRunning && _session.elapsed > Duration.zero)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onResume,
                        child: const Text('Resume'),
                      ),
                    )
                  else if (_session.isRunning)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onPause,
                        child: const Text('Pause'),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton(
                        onPressed: _onStart,
                        child: const Text('Start'),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          (_session.isRunning || _session.elapsed > Duration.zero)
                          ? _onStop
                          : null,
                      child: const Text('Stop'),
                    ),
                  ),
                ],
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
