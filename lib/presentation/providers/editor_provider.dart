import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/record_audio.dart';

/// Drives the Editor screen: live pitch/speed/echo/reverb sliders that
/// re-render a preview via ffmpeg after a short debounce, so dragging a
/// slider doesn't fire a new ffmpeg process on every frame. Playback is
/// manual (via [playPreview]/[pausePreview]) rather than auto-playing on
/// every slider tweak, so adjusting pitch repeatedly doesn't keep
/// interrupting what you're listening to.
class EditorProvider extends ChangeNotifier {
  final AudioRepository _repository;
  late final RecordAudio _recordAudio;
  EditorProvider(this._repository) {
    _recordAudio = RecordAudio(_repository);
  }

  String? sourcePath;
  String? previewPath;
  bool isRecording = false;

  double pitch = 0.0;   // -0.5 .. 0.5, 0 = no change
  double speed = 1.0;   // 0.5 .. 2.0, 1 = no change
  double echo = 0.0;    // 0 .. 1, 0 = off
  double reverb = 0.0;  // 0 .. 1, 0 = off

  bool isProcessing = false;
  String? errorMessage;
  bool _previewStarted = false;

  Timer? _debounce;

  Stream<Duration> get positionStream => _repository.playbackPosition;
  Stream<Duration> get durationStream => _repository.playbackDuration;
  Stream<bool> get isPlayingStream => _repository.isPlayingStream;

  /// Live dBFS readings while [isRecording] is true, for a live waveform
  /// visualizer on the "record a new clip" step.
  Stream<double> get amplitudeStream => _repository.recordingAmplitude;

  void attachSource(String path) {
    sourcePath = path;
    previewPath = null;
    pitch = 0.0;
    speed = 1.0;
    echo = 0.0;
    reverb = 0.0;
    errorMessage = null;
    _previewStarted = false;
    notifyListeners();
  }

  /// Starts capturing a brand-new clip to edit, instead of picking one
  /// already saved to the Library.
  Future<void> startRecordingNew() async {
    try {
      errorMessage = null;
      await _recordAudio.start();
      isRecording = true;
      notifyListeners();
    } on Failure catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Stops the fresh recording and loads it straight into the sliders,
  /// same as picking a saved recording would.
  Future<void> stopRecordingNew() async {
    try {
      final path = await _recordAudio.stop();
      isRecording = false;
      attachSource(path);
    } on Failure catch (e) {
      isRecording = false;
      errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Clears the current source so the Editor screen can show its
  /// recording picker again instead of the sliders.
  void clearSource() {
    _debounce?.cancel();
    sourcePath = null;
    previewPath = null;
    pitch = 0.0;
    speed = 1.0;
    echo = 0.0;
    reverb = 0.0;
    errorMessage = null;
    _previewStarted = false;
    notifyListeners();
  }

  void setPitch(double value) {
    pitch = value;
    notifyListeners();
    _scheduleDebounce();
  }

  void setSpeed(double value) {
    speed = value;
    notifyListeners();
    _scheduleDebounce();
  }

  void setEcho(double value) {
    echo = value;
    notifyListeners();
    _scheduleDebounce();
  }

  void setReverb(double value) {
    reverb = value;
    notifyListeners();
    _scheduleDebounce();
  }

  void _scheduleDebounce() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _renderPreview);
  }

  String _buildFilter() {
    final parts = <String>[];

    final pitchFactor = 1.0 + pitch;
    if ((pitchFactor - 1.0).abs() > 0.01) {
      parts.add('asetrate=44100*${pitchFactor.toStringAsFixed(3)}');
      parts.add('aresample=44100');
      parts.add('atempo=${(1 / pitchFactor).toStringAsFixed(3)}');
    }

    if ((speed - 1.0).abs() > 0.01) {
      parts.add('atempo=${speed.toStringAsFixed(3)}');
    }

    if (echo > 0.01) {
      final delay = (20 + echo * 100).round();
      final decay = (0.2 + echo * 0.5).toStringAsFixed(2);
      parts.add('aecho=0.8:0.9:$delay:$decay');
    }

    if (reverb > 0.01) {
      final d1 = (40 + reverb * 80).round();
      final d2 = (80 + reverb * 120).round();
      final d3 = (120 + reverb * 160).round();
      final dec = (0.15 + reverb * 0.2).toStringAsFixed(2);
      parts.add('aecho=0.8:0.9:$d1|$d2|$d3:$dec|$dec|$dec');
    }

    return parts.join(',');
  }

  Future<void> _renderPreview() async {
    final source = sourcePath;
    if (source == null) return;

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final filter = _buildFilter();
      final output = await _repository.applyCustomFilter(
        sourcePath: source,
        ffmpegFilter: filter,
      );
      previewPath = output;
      // A fresh render replaces whatever was loaded before, so the next
      // tap of Play should always start this new version from 0:00.
      _previewStarted = false;
      isProcessing = false;
      notifyListeners();
    } catch (e) {
      isProcessing = false;
      errorMessage = e.toString();
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
