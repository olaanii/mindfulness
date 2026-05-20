import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/mood/data/mood_repository.dart';
import 'package:mindfulness/widgets/mindful_ui.dart';

Future<void> showMoodCheckInSheet(
  BuildContext context,
  WidgetRef ref, {
  String? sessionId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MoodSheetScaffold(
      sessionId: sessionId,
      onSubmit: (before, after, note) async {
        final user = ref.read(authServiceProvider).currentUser;
        if (user == null) return;
        try {
          await ref
              .read(moodRepositoryProvider)
              .addEntry(
                userId: user.uid,
                moodBefore: before,
                moodAfter: after,
                sessionId: sessionId,
                note: note,
              );
          if (ctx.mounted) Navigator.of(ctx).pop();
        } catch (e) {
          if (!ctx.mounted) return;
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
        }
      },
    ),
  );
}

class _MoodSheetScaffold extends StatelessWidget {
  const _MoodSheetScaffold({required this.onSubmit, this.sessionId});

  final Future<void> Function(int before, int after, String? note) onSubmit;
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.paddingOf(context).bottom +
        24 +
        MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.headerGlass,
          border: Border.all(color: AppColors.glassBorder),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppColors.radiusXl),
          ),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: _MoodCheckInForm(sessionId: sessionId, onSubmit: onSubmit),
        ),
      ),
    );
  }
}

class _MoodCheckInForm extends StatefulWidget {
  const _MoodCheckInForm({required this.onSubmit, this.sessionId});

  final Future<void> Function(int before, int after, String? note) onSubmit;
  final String? sessionId;

  @override
  State<_MoodCheckInForm> createState() => _MoodCheckInFormState();
}

class _MoodCheckInFormState extends State<_MoodCheckInForm> {
  var _before = 3;
  var _after = 3;
  final _note = TextEditingController();
  var _busy = false;

  static const _labels = ['Very low', 'Low', 'Okay', 'Good', 'Great'];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineMuted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionEyebrow('Mindful reflection'),
        const SizedBox(height: 10),
        Text(
          'How are you feeling?',
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Take a brief pause and notice what shifted during your session.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ConcentricRings(
                      color: AppColors.accentCoral.withValues(alpha: 0.12),
                    ),
                    Text(
                      _emojiFor(_after),
                      style: const TextStyle(fontSize: 48),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _labels[_after - 1],
                style: text.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
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
              Text('Before', style: text.titleSmall),
              const SizedBox(height: 10),
              _MoodEmojiTrack(
                value: _before,
                onChanged: (v) => setState(() => _before = v),
              ),
              const SizedBox(height: 18),
              Text('After', style: text.titleSmall),
              const SizedBox(height: 10),
              _MoodEmojiTrack(
                value: _after,
                onChanged: (v) => setState(() => _after = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _note,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'A few words about what you noticed...',
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await widget.onSubmit(_before, _after, _note.text);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: _busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Note mood'),
        ),
      ],
    );
  }

  static String _emojiFor(int level) {
    const emojis = ['😔', '😕', '😐', '🙂', '😄'];
    return emojis[level - 1];
  }
}

class _ConcentricRings extends StatelessWidget {
  const _ConcentricRings({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 140),
      painter: _RingsPainter(color: color),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 3; i >= 1; i--) {
      final r = 28.0 * i;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.15 + (3 - i) * 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MoodEmojiTrack extends StatelessWidget {
  const _MoodEmojiTrack({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _emojis = ['😔', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: w * 0.1,
                right: w * 0.1,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 1; i <= 5; i++)
                    _EmojiDot(
                      emoji: _emojis[i - 1],
                      selected: value == i,
                      onTap: () => onChanged(i),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmojiDot extends StatelessWidget {
  const _EmojiDot({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? AppColors.primaryYellow
              : Colors.white.withValues(alpha: 0.65),
          border: Border.all(
            color: selected
                ? AppColors.accentCoral.withValues(alpha: 0.4)
                : AppColors.outlineMuted.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppColors.cardShadow(context) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
