import '../repositories/audio_repository.dart';

/// Encapsulates the "record audio from the microphone" business action.
/// A thin wrapper today, but having it as its own use case means recording
/// logic (e.g. future max-duration limits, auto-stop rules) has one place
/// to live without bloating the provider or repository.
class RecordAudio {
  final AudioRepository repository;
  const RecordAudio(this.repository);

  Future<void> start() => repository.startRecording();

  Future<String> stop() => repository.stopRecording();
}
