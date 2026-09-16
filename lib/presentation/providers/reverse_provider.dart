import 'package:flutter/material.dart';
import '../../core/constants/voice_effects.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/save_recording.dart';

/// Drives Reverse Studio: pick a recording, play it backwards (via the
/// same `applyCustomFilter` ffmpeg pipeline the Editor uses, with a plain
/// `areverse` filter), preview it, and save the result as a new
/// recording — reusing the same repository/use-case plumbing as
/// [RecorderProvider] and [EditorProvider] rather than inventing new
/// audio infrastructure.
class ReverseProvider extends ChangeNotifier {
  final AudioRepository _repository;
  late final SaveRecording _saveRecording;

  ReverseProvider(this._repository) {
    _saveRecording = SaveRecording(_repository);
  }

  String? sourcePath;
  String? previewPath;
  bool isProcessing = false;
  String? errorMessage;
  bool _previewStarted = false;

  Stream<Duration> get positionStream => _repository.playbackPosition;
  Stream<Duration> get durationStream => _repository.playbackDuration;
  Stream<bool> get isPlayingStream => _repository.isPlayingStream;

  /// Loads a recording and immediately starts reversing it.
  void attachSource(String path) {
    sourcePath = path;
    previewPath = null;
    errorMessage = null;
    _previewStarted = false;
    notifyListeners();
    _reverse();
  }

  /// Clears the current source so Reverse Studio can show its recording
  /// picker again instead of the preview.
  void clearSource() {
    sourcePath = null;
    previewPath = null;
    errorMessage = null;
    _previewStarted = false;
    notifyListeners();
  }

  Future<void> _reverse() async {
    final source = sourcePath;
    if (source == null) return;

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final output = await _repository.applyCustomFilter(
        sourcePath: source,
        ffmpegFilter: 'areverse',
      );
      previewPath = output;
      isProcessing = false;
      notifyListeners();
    } on Failure catch (e) {
      isProcessing = false;
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> playPreview() async {
    if (previewPath == null) return;
    try {
      if (_previewStarted) {
        await _repository.resumeAudio();
      } else {
        await _repository.playAudio(previewPath!);
        _previewStarted = true;
      }
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> pausePreview() => _repository.pauseAudio();

  Future<void> stopPreview() {
    _previewStarted = false;
    return _repository.stopAudio();
  }

  Future<Recording?> save(String title) async {
    if (previewPath == null) return null;
    try {
      final recording = await _saveRecording(
        sourcePath: previewPath!,
        title: title,
        appliedEffect: VoiceEffectType.reverse,
      );
      return recording;
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }
}
