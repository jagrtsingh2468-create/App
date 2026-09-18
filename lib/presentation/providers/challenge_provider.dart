import 'package:flutter/material.dart';
import '../../core/constants/voice_effects.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/record_audio.dart';
import '../../domain/usecases/save_recording.dart';

enum ChallengeStage {
  idle, // haven't started yet
  recordingOriginal, // capturing the phrase to challenge with
  processingOriginal, // reversing it into the "challenge" clip
  readyToMimic, // can listen to the reversed challenge + record an attempt
  recordingMimic, // capturing the user's attempt to say it backwards
  processingMimic, // reversing the attempt back to reveal how close it was
  result, // show original vs the "reveal", let the user save or retry
}

/// Drives Reverse Challenge mode: record (or import) a phrase, hear it
/// reversed, try to say the reversed version back convincingly, then
/// reverse that attempt again — if you nailed the mimic, the "reveal"
/// should sound close to the original phrase (usually it's hilariously
/// not).
///
/// Reuses the exact same `RecordAudio`/`applyCustomFilter('areverse')`/
/// `SaveRecording` building blocks as [RecorderProvider] and
/// [ReverseProvider] rather than duplicating audio plumbing.
class ChallengeProvider extends ChangeNotifier {
  final AudioRepository _repository;
  late final RecordAudio _recordAudio;
  late final SaveRecording _saveRecording;

  ChallengeProvider(this._repository) {
    _recordAudio = RecordAudio(_repository);
    _saveRecording = SaveRecording(_repository);
  }

  ChallengeStage stage = ChallengeStage.idle;
  String? originalPath;
  String? reversedChallengePath; // what the user needs to mimic by ear
  String? mimicPath;
  String? revealPath; // the mimic attempt, reversed back
  String? errorMessage;

  String? _loadedClip;
  bool _clipStarted = false;

  Stream<Duration> get positionStream => _repository.playbackPosition;
  Stream<Duration> get durationStream => _repository.playbackDuration;
  Stream<bool> get isPlayingStream => _repository.isPlayingStream;

  /// Live dBFS readings while actively recording either the original
  /// phrase or the mimic attempt, for a live waveform visualizer.
  Stream<double> get amplitudeStream => _repository.recordingAmplitude;

  Future<void> startRecordingOriginal() async {
    try {
      errorMessage = null;
      await _recordAudio.start();
      stage = ChallengeStage.recordingOriginal;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> stopRecordingOriginal() async {
    try {
      final path = await _recordAudio.stop();
      await _reverseOriginalAndAdvance(path);
    } on Failure catch (e) {
      errorMessage = e.message;
      stage = ChallengeStage.idle;
      notifyListeners();
    }
  }

  /// Lets the user import an existing audio file as the challenge phrase
  /// instead of recording a new one.
  Future<void> importOriginal() async {
    try {
      errorMessage = null;
      final path = await _repository.importAudioFile();
      if (path == null) return; // user cancelled the picker
      await _reverseOriginalAndAdvance(path);
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> _reverseOriginalAndAdvance(String path) async {
    originalPath = path;
    stage = ChallengeStage.processingOriginal;
    notifyListeners();

    final reversed = await _repository.applyCustomFilter(
      sourcePath: path,
      ffmpegFilter: 'areverse',
    );
    reversedChallengePath = reversed;
    stage = ChallengeStage.readyToMimic;
    notifyListeners();
  }

  Future<void> startRecordingMimic() async {
    try {
      errorMessage = null;
      await _recordAudio.start();
      stage = ChallengeStage.recordingMimic;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> stopRecordingMimic() async {
    try {
      final path = await _recordAudio.stop();
      mimicPath = path;
      stage = ChallengeStage.processingMimic;
      notifyListeners();

      final revealed = await _repository.applyCustomFilter(
        sourcePath: path,
        ffmpegFilter: 'areverse',
      );
      revealPath = revealed;
      stage = ChallengeStage.result;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      stage = ChallengeStage.readyToMimic;
      notifyListeners();
    }
  }

  /// Plays any of this session's clips by path (the reversed challenge,
  /// the original, or the final reveal). Switching to a different clip
  /// than what's currently loaded always starts it fresh from 0:00;
  /// replaying the same clip after a pause resumes in place.
  Future<void> playClip(String path) async {
    try {
      if (_loadedClip == path && _clipStarted) {
        await _repository.resumeAudio();
      } else {
        await _repository.playAudio(path);
        _loadedClip = path;
        _clipStarted = true;
      }
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<void> pausePlayback() => _repository.pauseAudio();

  Future<void> stopPlayback() {
    _clipStarted = false;
    return _repository.stopAudio();
  }

  Future<Recording?> saveReveal(String title) async {
    if (revealPath == null) return null;
    try {
      final recording = await _saveRecording(
        sourcePath: revealPath!,
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

  /// Starts a brand new round, discarding this session's clips.
  void reset() {
    stage = ChallengeStage.idle;
    originalPath = null;
    reversedChallengePath = null;
    mimicPath = null;
    revealPath = null;
    errorMessage = null;
    _loadedClip = null;
    _clipStarted = false;
    notifyListeners();
  }
}
