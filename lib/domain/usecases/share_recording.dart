import '../entities/recording.dart';
import '../repositories/audio_repository.dart';

/// Encapsulates "share this recording via the OS share sheet".
class ShareRecording {
  final AudioRepository repository;
  const ShareRecording(this.repository);

  Future<void> call(Recording recording) => repository.shareRecording(recording);
}
