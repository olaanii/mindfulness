import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/focus_timer/domain/focus_timer_models.dart';
import 'package:mindfulness/features/focus_timer/providers/focus_timer_providers.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

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
    final activeSeconds = timer.segment == FocusSegment.work
        ? timer.workLengthSec
        : timer.shortBreakLengthSec;
    final progress = activeSeconds == 0
        ? 0.0
        : ((activeSeconds - timer.remainingSeconds) / activeSeconds).clamp(
            0.0,
            1.0,
          );
    final body = ListView(
      padding: EdgeInsets.zero,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                timer.lifecycle == FocusLifecycle.idle
                    ? 'Ready to begin'
                    : timer.segment == FocusSegment.work
                    ? 'Deep Focus'
                    : 'Short Break',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textBrand,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 28),
              _CircularTimerCard(
                label: _formatMmSs(timer.remainingSeconds),
                subtitle: timer.lifecycle == FocusLifecycle.paused
                    ? 'Paused'
                    : timer.segment == FocusSegment.work
                    ? 'Deep Focus'
                    : 'Break',
                progress: progress,
                active: timer.lifecycle == FocusLifecycle.running,
              ),
              const SizedBox(height: 28),
              _TimerControls(
                lifecycle: timer.lifecycle,
                onStart: notifier.start,
                onPause: notifier.pause,
                onResume: notifier.resume,
                onReset: notifier.reset,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionEyebrow('Session lengths'),
              const SizedBox(height: 14),
              _MinutesSlider(
                enabled: timer.lifecycle == FocusLifecycle.idle,
                valueMinutes: (timer.workLengthSec / 60).round().clamp(5, 90),
                min: 5,
                max: 90,
                label: 'Focus',
                valueLabel: '${(timer.workLengthSec / 60).round()} min',
                onChanged: notifier.setWorkMinutes,
              ),
              const SizedBox(height: 18),
              _MinutesSlider(
                enabled: timer.lifecycle == FocusLifecycle.idle,
                valueMinutes: (timer.shortBreakLengthSec / 60).round().clamp(
                  1,
                  30,
                ),
                min: 1,
                max: 30,
                label: 'Break',
                valueLabel: '${(timer.shortBreakLengthSec / 60).round()} min',
                onChanged: notifier.setBreakMinutes,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionEyebrow('Soundscapes'),
              const SizedBox(height: 14),
              _SettingRow(
                icon: Icons.headphones_rounded,
                title: 'Play loop during focus',
                subtitle: 'Stream a soft background preview while you work.',
                trailing: Switch.adaptive(
                  value: timer.soundscapeEnabled,
                  onChanged: notifier.setSoundscapeEnabled,
                  activeThumbColor: AppColors.textBrand,
                  activeTrackColor: AppColors.primaryYellow,
                ),
              ),
              const SizedBox(height: 14),
              _VolumeRow(
                value: timer.volume,
                onChanged: timer.soundscapeEnabled ? notifier.setVolume : null,
              ),
            ],
          ),
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

class _CircularTimerCard extends StatelessWidget {
  const _CircularTimerCard({
    required this.label,
    required this.subtitle,
    required this.progress,
    required this.active,
  });

  final String label;
  final String subtitle;
  final double progress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) {
        return Container(
          width: 272,
          height: 272,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryYellow.withValues(alpha: 0.18),
            ),
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.72),
                AppColors.surface.withValues(alpha: 0.94),
              ],
            ),
            boxShadow: active
                ? AppColors.elevatedGlow(context)
                : AppColors.cardShadow(context),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  value: t,
                  strokeWidth: 12,
                  backgroundColor: AppColors.primaryYellow.withValues(
                    alpha: 0.12,
                  ),
                  color: AppColors.accentCoral,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Container(
                width: 206,
                height: 206,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.68),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: child,
              ),
            ],
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              letterSpacing: -1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textBrand),
          ),
        ],
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({
    required this.lifecycle,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  final FocusLifecycle lifecycle;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final primaryAction = lifecycle == FocusLifecycle.idle
        ? onStart
        : lifecycle == FocusLifecycle.running
        ? onPause
        : onResume;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.restart_alt_rounded,
          size: 52,
          onTap: lifecycle == FocusLifecycle.idle ? null : onReset,
        ),
        const SizedBox(width: 20),
        _ControlButton(
          icon: lifecycle == FocusLifecycle.running
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 84,
          primary: true,
          onTap: primaryAction,
        ),
        const SizedBox(width: 20),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: 52,
          onTap: lifecycle == FocusLifecycle.idle ? null : onReset,
        ),
      ],
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
    required this.valueLabel,
    required this.onChanged,
  });

  final bool enabled;
  final int valueMinutes;
  final int min;
  final int max;
  final String label;
  final String valueLabel;
  final void Function(int minutes) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: enabled ? null : AppColors.textMuted,
              ),
            ),
            Text(
              valueLabel,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textBrand),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.accentCoral,
            inactiveTrackColor: AppColors.textBrand.withValues(alpha: 0.12),
            thumbColor: AppColors.accentCoral,
            overlayColor: AppColors.accentCoral.withValues(alpha: 0.14),
          ),
          child: Slider(
            value: valueMinutes.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$valueMinutes min',
            onChanged: enabled ? (v) => onChanged(v.round()) : null,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.textBrand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq_rounded, color: AppColors.textBrand),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppColors.accentCoral,
                inactiveTrackColor: AppColors.textBrand.withValues(alpha: 0.12),
                thumbColor: AppColors.accentCoral,
                overlayColor: AppColors.accentCoral.withValues(alpha: 0.14),
              ),
              child: Slider(value: value, onChanged: onChanged),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textBrand),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
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
            color: primary
                ? AppColors.primaryYellow.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: primary
                  ? AppColors.primaryYellow.withValues(alpha: 0.35)
                  : AppColors.glassBorder,
            ),
            boxShadow: primary
                ? AppColors.elevatedGlow(context)
                : AppColors.cardShadow(context),
          ),
          child: Icon(
            icon,
            color: AppColors.textBrand,
            size: primary ? 36 : 24,
          ),
        ),
      ),
    );
  }
}
