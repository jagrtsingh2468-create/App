import '../../core/constants/voice_effects.dart';
import '../repositories/audio_repository.dart';

/// Encapsulates "transform this audio with the chosen voice effect".
class ApplyEffect {
  final AudioRepository repository;
  const ApplyEffect(this.repository);

  Future<String> call({
    required String sourcePath,
    required VoiceEffectType effect,
  }) {
    return repository.applyEffect(sourcePath: sourcePath, effect: effect);
  }
}
