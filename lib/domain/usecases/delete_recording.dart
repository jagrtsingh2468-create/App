import '../entities/recording.dart';
import '../repositories/audio_repository.dart';

/// Encapsulates "permanently remove this recording from disk + library".
class DeleteRecording {
  final AudioRepository repository;
  const DeleteRecording(this.repository);

  Future<void> call(Recording recording) => repository.deleteRecording(recording);
}
