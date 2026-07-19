import '../../core/constants/voice_effects.dart';
import '../entities/recording.dart';
import '../repositories/audio_repository.dart';

/// Encapsulates "save this processed clip to the user's library".
class SaveRecording {
  final AudioRepository repository;
  const SaveRecording(this.repository);

  Future<Recording> call({
    required String sourcePath,
    required String title,
    required VoiceEffectType appliedEffect,
  }) {
    return repository.saveRecording(
      sourcePath: sourcePath,
      title: title,
      appliedEffect: appliedEffect,
    );
  }
}
