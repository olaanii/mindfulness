import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindfulness/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mindfulness/features/auth/providers/auth_providers.dart';
import 'package:mindfulness/features/focus_timer/data/session_repository.dart';
import 'package:mindfulness/features/meditations/data/meditation_repository.dart';
import 'package:mindfulness/features/meditations/domain/meditation.dart';
import 'package:mindfulness/features/mood/presentation/mood_check_in_sheet.dart';

/// Logs a [sessions] row when the track completes or when the user leaves after
/// ≥ [kMinMeditationLogSeconds] of playback (partial listen).
const kMinMeditationLogSeconds = 15;

class MeditationPlayerScreen extends ConsumerStatefulWidget {
  const MeditationPlayerScreen({super.key, required this.meditationId});

  final String meditationId;

  @override
  ConsumerState<MeditationPlayerScreen> createState() =>
      _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends ConsumerState<MeditationPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  Meditation? _meditation;
  Object? _loadError;
  var _loading = true;
  var _loggedMeditationSession = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      final m = await ref
          .read(meditationRepositoryProvider)
          .getById(widget.meditationId);
      if (!mounted) return;
      if (m == null || m.audioUrl.isEmpty) {
        setState(() {
          _meditation = m;
          _loading = false;
          _loadError = m == null ? 'Meditation not found' : 'Missing audio URL';
        });
        return;
      }
      setState(() {
        _meditation = m;
        _loading = false;
      });
      await _player.setAudioSource(AudioSource.uri(Uri.parse(m.audioUrl)));
      await _playerStateSub?.cancel();
      _playerStateSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          unawaited(_tryLogCompletedSession());
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _tryLogCompletedSession() async {
    if (_loggedMeditationSession) return;
    final m = _meditation;
    final user = ref.read(authServiceProvider).currentUser;
    if (m == null || user == null) return;
    var sec = m.durationSec;
    if (sec <= 0) {
      sec = _player.duration?.inSeconds ?? _player.position.inSeconds;
    }
    if (sec < kMinMeditationLogSeconds) return;
    _loggedMeditationSession = true;
    try {
      final id = await ref.read(sessionRepositoryProvider).logMeditationSession(
        userId: user.uid,
        durationSeconds: sec,
        meditationId: m.id,
      );
      if (mounted) {
        await showMoodCheckInSheet(context, ref, sessionId: id);
      }
    } catch (_) {}
  }

  Future<void> _tryLogPartialListen() async {
    if (_loggedMeditationSession) return;
    final m = _meditation;
    final user = ref.read(authServiceProvider).currentUser;
    if (m == null || user == null) return;
    final pos = _player.position.inSeconds;
    if (pos < kMinMeditationLogSeconds) return;
    _loggedMeditationSession = true;
    try {
      final id = await ref.read(sessionRepositoryProvider).logMeditationSession(
        userId: user.uid,
        durationSeconds: pos,
        meditationId: m.id,
      );
      if (mounted) {
        await showMoodCheckInSheet(context, ref, sessionId: id);
      }
    } catch (_) {}
  }

  Future<void> _exit() async {
    await _tryLogPartialListen();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    unawaited(_playerStateSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  String _format(Duration d) {
    final t = d.inSeconds;
    final m = t ~/ 60;
    final s = t % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final m = _meditation;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exit,
          ),
          title: Text(m?.title ?? 'Meditation'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _loadError.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (m != null) ...[
                      Text(
                        m.durationLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(m.category),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                    const Spacer(),
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      initialData: Duration.zero,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration?>(
                          stream: _player.durationStream,
                          builder: (context, durSnap) {
                            final dur = durSnap.data ?? Duration.zero;
                            final maxMs = dur.inMilliseconds.clamp(1, 1 << 31);
                            final value =
                                pos.inMilliseconds.clamp(0, maxMs).toDouble();
                            return Column(
                              children: [
                                Slider(
                                  max: maxMs.toDouble(),
                                  value: value,
                                  onChanged: dur == Duration.zero
                                      ? null
                                      : (v) {
                                          unawaited(
                                            _player.seek(
                                              Duration(milliseconds: v.round()),
                                            ),
                                          );
                                        },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_format(pos)),
                                      Text(_format(dur)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (context, snap) {
                        final playing = snap.data?.playing ?? false;
                        final processing = snap.data?.processingState;
                        final busy =
                            processing == ProcessingState.loading ||
                            processing == ProcessingState.buffering;
                        return IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.accentCoral,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(20),
                          ),
                          iconSize: 48,
                          onPressed: busy
                              ? null
                              : () => playing ? _player.pause() : _player.play(),
                          icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
      ),
    );
  }
}
