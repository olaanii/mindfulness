import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// HTTPS preview loop — swap for [AudioSource.asset] when bundling offline loops.
const focusSoundscapePreviewUrl =
    'https://samplelib.com/lib/preview/mp3/sample-3s.mp3';

final class FocusSoundPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> dispose() => _player.dispose();

  Future<void> configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> prepare() async {
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(focusSoundscapePreviewUrl)),
    );
    await _player.setLoopMode(LoopMode.all);
  }

  void setVolume(double value) => _player.setVolume(value.clamp(0, 1));

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();
}
