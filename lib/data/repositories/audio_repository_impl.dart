import '../../core/constants/voice_effects.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/audio_repository.dart';
import '../models/recording_model.dart';
import '../services/audio_effects_service.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/storage_service.dart';

/// Concrete implementation of [AudioRepository]. Composes the four
/// single-responsibility services (recorder, effects, player, storage)
/// behind the domain-facing interface. This is the only class in the app
/// that knows about all four at once.
class AudioRepositoryImpl implements AudioRepository {
  final AudioRecorderService _recorderService;
  final AudioEffectsService _effectsService;
  final AudioPlayerService _playerService;
  final StorageService _storageService;

  AudioRepositoryImpl({
    AudioRecorderService? recorderService,
    AudioEffectsService? effectsService,
    AudioPlayerService? playerService,
    StorageService? storageService,
  })  : _recorderService = recorderService ?? AudioRecorderService(),
        _effectsService = effectsService ?? AudioEffectsService(),
        _playerService = playerService ?? AudioPlayerService(),
        _storageService = storageService ?? StorageService();

  @override
  Future<void> startRecording() => _recorderService.start();

  @override
  Future<String> stopRecording() => _recorderService.stop();

  @override
  Future<bool> isRecording() => _recorderService.isRecording();

  @override
  Future<String?> importAudioFile() => _storageService.importAudioFile();

  @override
  Future<String> applyEffect({
    required String sourcePath,
    required VoiceEffectType effect,
  }) {
    return _effectsService.apply(sourcePath: sourcePath, effect: effect);
  }

  @override
  Future<void> playAudio(String filePath) => _playerService.play(filePath);

  @override
  Future<void> pauseAudio() => _playerService.pause();

  @override
  Future<void> stopAudio() => _playerService.stop();

  @override
  Stream<Duration> get playbackPosition => _playerService.positionStream;

  @override
  Stream<Duration> get playbackDuration => _playerService.durationStream;

  @override
  Stream<bool> get isPlayingStream => _playerService.isPlayingStream;

  @override
  Future<Recording> saveRecording({
    required String sourcePath,
    required String title,
    required VoiceEffectType appliedEffect,
  }) async {
    final duration = await _effectsService.probeDuration(sourcePath);
    return _storageService.save(
      sourcePath: sourcePath,
      title: title,
      appliedEffect: appliedEffect,
      duration: duration,
    );
  }

  @override
  Future<List<Recording>> getSavedRecordings() => _storageService.getAll();

  @override
  Future<void> deleteRecording(Recording recording) {
    return _storageService.delete(RecordingModel.fromEntity(recording));
  }

  @override
  Future<void> shareRecording(Recording recording) {
    return _storageService.share(RecordingModel.fromEntity(recording));
  }

  @override
  Future<Duration> probeDuration(String filePath) {
    return _effectsService.probeDuration(filePath);
  }
}
