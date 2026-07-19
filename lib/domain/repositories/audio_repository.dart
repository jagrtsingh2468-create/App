import '../../core/constants/voice_effects.dart';
import '../entities/recording.dart';

/// Contract the data layer must fulfill. Use cases and providers depend on
/// this abstraction only, so the underlying recording/processing/storage
/// implementation (ffmpeg, record plugin, etc.) can be swapped without
/// touching business logic or UI.
abstract class AudioRepository {
  /// Starts capturing microphone input. Returns immediately; call
  /// [stopRecording] to finish and get back the raw file path.
  Future<void> startRecording();

  /// Stops the active recording and returns the path to the raw audio file.
  Future<String> stopRecording();

  Future<bool> isRecording();

  /// Lets the user pick an existing audio file from device storage.
  /// Returns null if the user cancelled the picker.
  Future<String?> importAudioFile();

  /// Applies [effect] to the audio at [sourcePath] and returns the path to
  /// the newly rendered output file. When [effect] is [VoiceEffectType.none]
  /// the source is simply copied through unchanged.
  Future<String> applyEffect({
    required String sourcePath,
    required VoiceEffectType effect,
  });

  Future<void> playAudio(String filePath);
  Future<void> pauseAudio();
  Future<void> stopAudio();
  Stream<Duration> get playbackPosition;
  Stream<Duration> get playbackDuration;
  Stream<bool> get isPlayingStream;

  /// Persists a finished recording into the app's permanent library and
  /// returns the saved [Recording] entity.
  Future<Recording> saveRecording({
    required String sourcePath,
    required String title,
    required VoiceEffectType appliedEffect,
  });

  Future<List<Recording>> getSavedRecordings();

  Future<void> deleteRecording(Recording recording);

  Future<void> shareRecording(Recording recording);

  Future<Duration> probeDuration(String filePath);
}
