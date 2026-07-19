import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Filesystem helpers shared across services. Keeping path logic here
/// avoids subtly-different directory handling scattered across the app.
class FileUtils {
  FileUtils._();

  static const _uuid = Uuid();

  /// Directory (inside app-private storage) where finished recordings live.
  /// Using app-private storage means we never need broad "manage external
  /// storage" permissions just to keep the user's own recordings.
  static Future<Directory> recordingsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'recordings'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Scratch space for raw mic capture + intermediate ffmpeg output, wiped
  /// automatically by the OS when it needs space (unlike documents dir).
  static Future<Directory> tempDirectory() async {
    final dir = await getTemporaryDirectory();
    return dir;
  }

  /// Generates a fresh unique file path for a new recording.
  static Future<String> newRecordingPath({String extension = 'm4a'}) async {
    final dir = await recordingsDirectory();
    final fileName = 'voice_${_uuid.v4()}.$extension';
    return p.join(dir.path, fileName);
  }

  static Future<String> newTempPath({String extension = 'm4a'}) async {
    final dir = await tempDirectory();
    final fileName = 'tmp_${_uuid.v4()}.$extension';
    return p.join(dir.path, fileName);
  }

  static String humanFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String humanDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
