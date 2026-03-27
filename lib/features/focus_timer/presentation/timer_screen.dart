import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/features/focus_timer/domain/focus_timer_models.dart';
import 'package:mindfulness/features/focus_timer/providers/focus_timer_providers.dart';

String _formatMmSs(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key, this.embedded = false});

  /// When true, omits [Scaffold] / [AppBar] for use inside [TabBarView].
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);
    final notifier = ref.read(focusTimerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final body = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _PhaseLabel(segment: timer.segment, lifecycle: timer.lifecycle),
          const SizedBox(height: 16),
          Center(
            child: _CountdownRing(
              label: _formatMmSs(timer.remainingSeconds),
              active: timer.lifecycle == FocusLifecycle.running,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (timer.lifecycle == FocusLifecycle.idle) ...[
                FilledButton.icon(
                  onPressed: () => notifier.start(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ],
              if (timer.lifecycle == FocusLifecycle.running) ...[
                FilledButton.tonalIcon(
                  onPressed: () => notifier.pause(),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              ],
              if (timer.lifecycle == FocusLifecycle.paused) ...[
                FilledButton.icon(
                  onPressed: () => notifier.resume(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
              ],
              if (timer.lifecycle != FocusLifecycle.idle) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => notifier.reset(),
                  child: const Text('Reset'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Durations (when idle)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _MinutesSlider(
            enabled: timer.lifecycle == FocusLifecycle.idle,
            valueMinutes: (timer.workLengthSec / 60).round().clamp(5, 90),
            min: 5,
            max: 90,
            label: 'Focus (${(timer.workLengthSec / 60).round()} min)',
            onChanged: notifier.setWorkMinutes,
          ),
          _MinutesSlider(
            enabled: timer.lifecycle == FocusLifecycle.idle,
            valueMinutes:
                (timer.shortBreakLengthSec / 60).round().clamp(1, 30),
            min: 1,
            max: 30,
            label: 'Break (${(timer.shortBreakLengthSec / 60).round()} min)',
            onChanged: notifier.setBreakMinutes,
          ),
          const SizedBox(height: 16),
          Text('Soundscape', style: Theme.of(context).textTheme.titleSmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Play loop during focus'),
            subtitle: Text(
              'Uses a short streamed preview (add bundled assets for offline).',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            value: timer.soundscapeEnabled,
            onChanged: (v) => notifier.setSoundscapeEnabled(v),
          ),
          Text('Volume', style: Theme.of(context).textTheme.bodySmall),
          Slider(
            value: timer.volume,
            onChanged: notifier.setVolume,
          ),
        ],
      );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus timer')),
      body: body,
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({required this.segment, required this.lifecycle});

  final FocusSegment segment;
  final FocusLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    String text;
    if (lifecycle == FocusLifecycle.idle) {
      text = 'Ready — tap Start when you are set';
    } else if (segment == FocusSegment.work) {
      text = lifecycle == FocusLifecycle.paused ? 'Focus (paused)' : 'Focus';
    } else {
      text = lifecycle == FocusLifecycle.paused ? 'Break (paused)' : 'Break';
    }
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
      textAlign: TextAlign.center,
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Color.lerp(
                    scheme.outlineVariant,
                    scheme.primary,
                    t,
                  ) ??
                  scheme.outlineVariant,
              width: 6,
            ),
          ),
          child: child,
        );
      },
      child: Text(
        label,
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _MinutesSlider extends StatelessWidget {
  const _MinutesSlider({
    required this.enabled,
    required this.valueMinutes,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  final bool enabled;
  final int valueMinutes;
  final int min;
  final int max;
  final String label;
  final void Function(int minutes) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Slider(
          value: valueMinutes.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$valueMinutes min',
          onChanged: enabled
              ? (v) => onChanged(v.round())
              : null,
        ),
      ],
    );
  }
}
