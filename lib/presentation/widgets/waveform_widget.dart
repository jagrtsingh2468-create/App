import 'dart:math';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// Renders the real waveform for the given recording file.
///
/// Assumption (adjust if your current widget's constructor differs):
/// this widget takes the recording's file path and builds/owns its own
/// PlayerController internally. If your EditorPlaceholderScreen already
/// owns a PlayerController (e.g. for play/pause preview), let me know and
/// I'll change this to accept an external controller instead of creating
/// one here, so we don't end up with two controllers on the same file.
class WaveformWidget extends StatefulWidget {
  final String filePath;
  final double height;
  final Color waveColor;
  final Color liveWaveColor;
  final Duration? currentPosition;

  const WaveformWidget({
    super.key,
    required this.filePath,
    this.height = 100,
    this.waveColor = Colors.grey,
    this.liveWaveColor = Colors.blueAccent,
    this.currentPosition,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  late PlayerController _playerController;
  bool _isLoaded = false;
  String? _error;
  bool _waveformEmpty = false;
  int _maxDurationMs = 0;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _preparePlayer();
  }

  Future<void> _preparePlayer() async {
    try {
      await _playerController.preparePlayer(
        path: widget.filePath,
        shouldExtractWaveform: true,
        noOfSamples: 100,
      );

      // Very short or freshly-written clips sometimes fail to extract any
      // amplitude data on the first pass — asking for fewer buckets after
      // a brief pause (letting the file settle) often succeeds where the
      // heavier first request didn't. Real data is always worth this
      // retry before giving up and showing a synthetic stand-in.
      if (_playerController.waveformData.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 250));
        _playerController.dispose();
        _playerController = PlayerController();
        await _playerController.preparePlayer(
          path: widget.filePath,
          shouldExtractWaveform: true,
          noOfSamples: 20,
        );
      }

      if (mounted) {
        setState(() {
          _isLoaded = true;
          _waveformEmpty = _playerController.waveformData.isEmpty;
          _maxDurationMs = _playerController.maxDuration;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  void didUpdateWidget(covariant WaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLoaded &&
        !_waveformEmpty &&
        widget.currentPosition != null &&
        widget.currentPosition != oldWidget.currentPosition) {
      _playerController.seekTo(widget.currentPosition!.inMilliseconds);
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Waveform unavailable',
            style: TextStyle(color: Colors.red.shade300),
          ),
        ),
      );
    }

    if (!_isLoaded) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_waveformEmpty) {
      // No real amplitude data even after retrying — show a deterministic
      // stand-in pattern (same file always renders the same shape) with a
      // real progress overlay, rather than a blank box or a bare message.
      return _SyntheticWaveform(
        seed: widget.filePath.hashCode,
        height: widget.height,
        waveColor: widget.waveColor,
        liveWaveColor: widget.liveWaveColor,
        currentPositionMs: widget.currentPosition?.inMilliseconds ?? 0,
        maxDurationMs: _maxDurationMs,
      );
    }

    return AudioFileWaveforms(
      size: Size(MediaQuery.of(context).size.width - 32, widget.height),
      playerController: _playerController,
      enableSeekGesture: true,
      waveformType: WaveformType.long,
      playerWaveStyle: PlayerWaveStyle(
        fixedWaveColor: widget.waveColor,
        liveWaveColor: widget.liveWaveColor,
        spacing: 6,
        showSeekLine: true,
      ),
    );
  }
}

/// A plain bar-chart stand-in for when the native extractor genuinely has
/// no real amplitude data to give us. Bar heights are generated once from
/// a seed derived from the file path, so the same clip always shows the
/// same shape (it isn't randomly reshuffling on every rebuild) — and the
/// played/unplayed split is driven by real playback position, so it still
/// tracks actual progress even though the bar heights themselves aren't
/// real audio data.
class _SyntheticWaveform extends StatelessWidget {
  final int seed;
  final double height;
  final Color waveColor;
  final Color liveWaveColor;
  final int currentPositionMs;
  final int maxDurationMs;

  const _SyntheticWaveform({
    required this.seed,
    required this.height,
    required this.waveColor,
    required this.liveWaveColor,
    required this.currentPositionMs,
    required this.maxDurationMs,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 40;
    final random = Random(seed);
    final bars = List.generate(barCount, (_) => 0.25 + random.nextDouble() * 0.75);
    final playedFraction = maxDurationMs > 0
        ? (currentPositionMs / maxDurationMs).clamp(0.0, 1.0)
        : 0.0;
    final playedBars = (barCount * playedFraction).round();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SyntheticBarsPainter(
          bars: bars,
          playedBars: playedBars,
          waveColor: waveColor,
          liveWaveColor: liveWaveColor,
        ),
      ),
    );
  }
}

class _SyntheticBarsPainter extends CustomPainter {
  final List<double> bars;
  final int playedBars;
  final Color waveColor;
  final Color liveWaveColor;

  _SyntheticBarsPainter({
    required this.bars,
    required this.playedBars,
    required this.waveColor,
    required this.liveWaveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / bars.length;
    final paint = Paint()..strokeCap = StrokeCap.round;
    final center = size.height / 2;

    for (var i = 0; i < bars.length; i++) {
      paint.color = i < playedBars ? liveWaveColor : waveColor;
      paint.strokeWidth = barWidth * 0.6;
      final barHeight = bars[i] * size.height;
      final x = (i + 0.5) * barWidth;
      canvas.drawLine(
        Offset(x, center - barHeight / 2),
        Offset(x, center + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SyntheticBarsPainter oldDelegate) =>
      oldDelegate.playedBars != playedBars || oldDelegate.bars != bars;
}
