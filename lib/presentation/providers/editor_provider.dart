import 'dart:async';
import '../../domain/repositories/audio_repository.dart';

/// Drives the Editor screen: live pitch/speed/echo/reverb sliders that
/// re-render a preview via ffmpeg after a short debounce, so dragging a
/// slider doesn't fire a new ffmpeg process on every frame.
class EditorProvider {
  final AudioRepository_repository;
  EditorProvider(this._repository);

  String? sourcePath;
  String? previewPath;

  double pitch = 0.0;   // -0.5 .. 0.5, 0 = no change
  double speed = 1.0;   // 0.5 .. 2.0, 1 = no change
  double echo = 0.0;    // 0 .. 1, 0 = off
  double reverb = 0.0;  // 0 .. 1, 0 = off

  bool isProcessing = false;
  String? errorMessage;

  Timer? _debounce;
  final _controller = StreamController<void>.broadcast();
  Stream<void> get onChange => _controller.stream;

  void attachSource(String path) {
    sourcePath = path;
    previewPath = null;
    pitch = 0.0;
    speed = 1.0;
    echo = 0.0;
    reverb = 0.0;
    errorMessage = null;
    _controller.add(null);
  }

  void setPitch(double value) {
    pitch = value;
    _controller.add(null);
    _scheduleDebounce();
  }

  void setSpeed(double value) {
    speed = value;
    _controller.add(null);
    _scheduleDebounce();
  }

  void setEcho(double value) {
    echo = value;
    _controller.add(null);
    _scheduleDebounce();
  }

  void setReverb(double value) {
    reverb = value;
    _controller.add(null);
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
    _controller.add(null);

    try {
      final filter = _buildFilter();
      final output = await _repository.applyCustomFilter(
        sourcePath: source,
        ffmpegFilter: filter,
      );
      previewPath = output;
      isProcessing = false;
      _controller.add(null);
      await _repository.playAudio(output);
    } catch (e) {
      isProcessing = false;
      errorMessage = e.toString();
      _controller.add(null);
    }
  }

  void dispose() {
    _debounce?.cancel();
    _controller.close();
  }
}
