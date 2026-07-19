import 'package:flutter/material.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/delete_recording.dart';
import '../../domain/usecases/share_recording.dart';

/// Manages the "My Recordings" library screen: loading saved clips,
/// deleting them, sharing them, and driving their playback.
class LibraryProvider extends ChangeNotifier {
  final AudioRepository _repository;
  late final DeleteRecording _deleteRecording;
  late final ShareRecording _shareRecording;

  LibraryProvider(this._repository) {
    _deleteRecording = DeleteRecording(_repository);
    _shareRecording = ShareRecording(_repository);
    loadRecordings();
  }

  List<Recording> recordings = [];
  bool isLoading = true;
  String? errorMessage;
  String? playingId;

  Future<void> loadRecordings() async {
    isLoading = true;
    notifyListeners();
    try {
      recordings = await _repository.getSavedRecordings();
      errorMessage = null;
    } on Failure catch (e) {
      errorMessage = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay(Recording recording) async {
    try {
      if (playingId == recording.id) {
        await _repository.stopAudio();
        playingId = null;
      } else {
        await _repository.playAudio(recording.filePath);
        playingId = recording.id;
      }
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> delete(Recording recording) async {
    try {
      await _deleteRecording(recording);
      recordings.removeWhere((r) => r.id == recording.id);
      if (playingId == recording.id) playingId = null;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> share(Recording recording) async {
    try {
      await _shareRecording(recording);
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
