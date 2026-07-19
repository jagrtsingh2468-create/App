import 'package:flutter/material.dart';
import '../../core/constants/voice_effects.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/apply_effect.dart';
import '../../domain/usecases/record_audio.dart';
import '../../domain/usecases/save_recording.dart';

enum RecorderStage {
  idle, // nothing recorded/imported yet
  recording, // mic actively capturing
  sourceReady, // have raw audio (recorded or imported), no effect applied yet
  processing, // ffmpeg is rendering the chosen effect
  previewReady, // processed audio ready to play/save
  saving,
}

/// Drives the full "capture -> transform -> preview -> save" flow that the
/// Record and Effects screens are built around. Kept separate from
/// [LibraryProvider] since the two have very different lifecycles.
class RecorderProvider extends ChangeNotifier {
  final AudioRepository _repository;
  late final RecordAudio _recordAudio;
  late final ApplyEffect _applyEffect;
  late final SaveRecording _saveRecording;

  RecorderProvider(this._repository) {
    _recordAudio = RecordAudio(_repository);
    _applyEffect = ApplyEffect(_repository);
    _saveRecording = SaveRecording(_repository);
  }

  RecorderStage stage = RecorderStage.idle;
  String? sourcePath; // raw recorded / imported audio
  String? previewPath; // effect-processed audio ready to play
  VoiceEffectType selectedEffect = VoiceEffectType.none;
  String? errorMessage;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  Stream<Duration> get positionStream => _repository.playbackPosition;
  Stream<Duration> get durationStream => _repository.playbackDuration;
  Stream<bool> get isPlayingStream => _repository.isPlayingStream;

  Future<void> startRecording() async {
    try {
      errorMessage = null;
      await _recordAudio.start();
      stage = RecorderStage.recording;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _recordAudio.stop();
      sourcePath = path;
      previewPath = null;
      selectedEffect = VoiceEffectType.none;
      stage = RecorderStage.sourceReady;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      stage = RecorderStage.idle;
      notifyListeners();
    }
  }

  /// Opens the system file picker and returns the temp path of the
  /// imported file (or null if cancelled), without mutating [stage].
  /// Callers combine this with [setImportedSource] once they're ready to
  /// navigate into the record/effects flow.
  Future<String?> importFileAndReturnPath() async {
    try {
      errorMessage = null;
      return await _repository.importAudioFile();
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }

  void setImportedSource(String path) {
    sourcePath = path;
    previewPath = null;
    selectedEffect = VoiceEffectType.none;
    errorMessage = null;
    stage = RecorderStage.sourceReady;
    notifyListeners();
  }

  /// Applies [effect] to the current [sourcePath] and moves to preview.
  Future<void> selectEffect(VoiceEffectType effect) async {
    if (sourcePath == null) return;

    selectedEffect = effect;
    stage = RecorderStage.processing;
    errorMessage = null;
    notifyListeners();

    try {
      final output = await _applyEffect(
        sourcePath: sourcePath!,
        effect: effect,
      );
      previewPath = output;
      stage = RecorderStage.previewReady;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      stage = RecorderStage.sourceReady;
      notifyListeners();
    }
  }

  Future<void> playPreview() async {
    if (previewPath == null) return;
    try {
      await _repository.playAudio(previewPath!);
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> pausePreview() => _repository.pauseAudio();

  Future<void> stopPreview() => _repository.stopAudio();

  Future<Recording?> save(String title) async {
    if (previewPath == null) return null;
    stage = RecorderStage.saving;
    notifyListeners();

    try {
      final recording = await _saveRecording(
        sourcePath: previewPath!,
        title: title,
        appliedEffect: selectedEffect,
      );
      reset();
      return recording;
    } on Failure catch (e) {
      errorMessage = e.message;
      stage = RecorderStage.previewReady;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    stage = RecorderStage.idle;
    sourcePath = null;
    previewPath = null;
    selectedEffect = VoiceEffectType.none;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
