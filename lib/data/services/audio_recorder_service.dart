import 'package:record/record.dart';
import '../../core/error/failures.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/permission_util.dart';

/// Thin wrapper around the `record` package. Handles permission checks,
/// output path generation, and translates plugin errors into our own
/// [Failure] types so upper layers never need to know about `record`
/// directly (keeps the dependency swappable).
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<void> start() async {
    await PermissionUtil.ensureMicrophonePermission();

    if (await _recorder.isRecording()) {
      throw const RecordingFailure('A recording is already in progress.');
    }

    final path = await FileUtils.newTempPath(extension: 'm4a');
    _currentPath = path;

    try {
      // AAC-LC at 44.1kHz/128kbps: small file size, wide device support,
      // and plenty of quality headroom for the pitch/speed effects below.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
    } catch (e) {
      throw RecordingFailure('Could not start recording: $e');
    }
  }

  Future<String> stop() async {
    try {
      final path = await _recorder.stop();
      final finalPath = path ?? _currentPath;
      if (finalPath == null) {
        throw const RecordingFailure('Recording produced no output file.');
      }
      return finalPath;
    } catch (e) {
      throw RecordingFailure('Could not stop recording: $e');
    }
  }

  Future<bool> isRecording() => _recorder.isRecording();

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
