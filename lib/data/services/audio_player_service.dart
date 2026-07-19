import 'package:audioplayers/audioplayers.dart';
import '../../core/error/failures.dart';

/// Thin wrapper around `audioplayers`, exposing just what the app needs:
/// play/pause/stop plus position, duration, and playing-state streams for
/// driving the waveform / seek-bar UI.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;
  Stream<bool> get isPlayingStream =>
      _player.onPlayerStateChanged.map((s) => s == PlayerState.playing);

  Future<void> play(String filePath) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      throw ProcessingFailure('Could not play audio: $e');
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() => _player.dispose();
}
