import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/voice_effects.dart';
import '../../core/error/failures.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/permission_util.dart';
import '../models/recording_model.dart';

/// Owns everything related to persisting recordings on disk and in the
/// lightweight local "database" (a JSON list in SharedPreferences - plenty
/// for a library of short audio clips; a real SQL DB would be overkill).
class StorageService {
  static const _prefsKey = 'saved_recordings_v1';
  static const _uuid = Uuid();

  /// Opens the system file picker restricted to audio files.
  /// Returns the path to a temp copy of the picked file, or null if the
  /// user cancelled.
  Future<String?> importAudioFile() async {
    await PermissionUtil.ensureStoragePermission();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null || result.files.isEmpty) return null;

    final pickedPath = result.files.single.path;
    if (pickedPath == null) {
      throw const ImportFailure('Could not read the selected file.');
    }

    // Copy into our temp working area so the original stays untouched and
    // we don't depend on a content:// URI staying valid.
    final destPath = await FileUtils.newTempPath(
      extension: p.extension(pickedPath).replaceFirst('.', ''),
    );
    await File(pickedPath).copy(destPath);
    return destPath;
  }

  /// Copies [sourcePath] into permanent app storage and records its
  /// metadata in the local library index.
  Future<RecordingModel> save({
    required String sourcePath,
    required String title,
    required VoiceEffectType appliedEffect,
    required Duration duration,
  }) async {
    final destPath = await FileUtils.newRecordingPath(
      extension: p.extension(sourcePath).replaceFirst('.', ''),
    );

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const StorageFailure('Source audio file no longer exists.');
    }
    await sourceFile.copy(destPath);

    final size = await File(destPath).length();

    final model = RecordingModel(
      id: _uuid.v4(),
      filePath: destPath,
      title: title,
      createdAt: DateTime.now(),
      duration: duration,
      fileSizeBytes: size,
      appliedEffect: appliedEffect,
    );

    final all = await getAll();
    all.insert(0, model); // newest first
    await _persist(all);

    return model;
  }

  Future<List<RecordingModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];

    final list = (jsonDecode(raw) as List)
        .map((e) => RecordingModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Defensive filter: drop entries whose backing file was somehow lost
    // (e.g. cleared by OS storage pressure) so the UI never shows dead rows.
    final existing = <RecordingModel>[];
    for (final r in list) {
      if (await File(r.filePath).exists()) existing.add(r);
    }
    if (existing.length != list.length) {
      await _persist(existing);
    }
    return existing;
  }

  Future<void> delete(RecordingModel recording) async {
    final all = await getAll();
    all.removeWhere((r) => r.id == recording.id);
    await _persist(all);

    final file = File(recording.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> share(RecordingModel recording) async {
    final file = File(recording.filePath);
    if (!await file.exists()) {
      throw const StorageFailure('File no longer exists.');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(recording.filePath)],
        text: 'Check out this voice clip I made with Voice Changer!',
      ),
    );
  }

  Future<void> _persist(List<RecordingModel> recordings) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(recordings.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }
}
