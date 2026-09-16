import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';

/// Real-time bar visualizer driven by a live dBFS amplitude stream (from
/// the active recording). Unlike [WaveformWidget] (which reads samples
/// from a finished file), this has no file to read yet — it just plots
/// each amplitude reading as it arrives, scrolling right to left like a
/// typical voice-memo recorder UI.
class LiveWaveformWidget extends StatefulWidget {
  final Stream<double> amplitudeStream;
  final bool isActive;
  final double height;
  final Color barColor;

  const LiveWaveformWidget({
    super.key,
    required this.amplitudeStream,
    required this.isActive,
    this.height = 80,
    this.barColor = Colors.redAccent,
  });

  @override
  State<LiveWaveformWidget> createState() => _LiveWaveformWidgetState();
}

class _LiveWaveformWidgetState extends State<LiveWaveformWidget> {
  static const int _maxBars = 40;
  final ListQueue<double> _levels = ListQueue<double>();
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _subscribe();
  }

  @override
  void didUpdateWidget(covariant LiveWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && _sub == null) {
      _subscribe();
    } else if (!widget.isActive && _sub != null) {
      _sub?.cancel();
      _sub = null;
      setState(_levels.clear);
    }
  }

  void _subscribe() {
    _sub = widget.amplitudeStream.listen((dbfs) {
      // Typical speech sits roughly -50..0 dBFS; map that to a 0..1 bar
      // height, with a small floor so silence still shows a faint bar
      // rather than nothing at all.
      final normalized = ((dbfs + 50) / 50).clamp(0.0, 1.0);
      final level = 0.05 + normalized * 0.95;
      if (!mounted) return;
      setState(() {
        _levels.addLast(level);
        if (_levels.length > _maxBars) _levels.removeFirst();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarsPainter(
          levels: _levels.toList(growable: false),
          maxBars: _maxBars,
          color: widget.barColor,
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> levels;
  final int maxBars;
  final Color color;

  _BarsPainter({required this.levels, required this.maxBars, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;

    final barWidth = size.width / maxBars;
    final paint = Paint()
      ..color = color
      ..strokeWidth = barWidth * 0.6
      ..strokeCap = StrokeCap.round;

    // Right-align so newest bar is always at the right edge, like audio
    // scrolling in from the right as it's captured.
    final startIndex = maxBars - levels.length;
    for (var i = 0; i < levels.length; i++) {
      final x = (startIndex + i + 0.5) * barWidth;
      final barHeight = levels[i] * size.height;
      final center = size.height / 2;
      canvas.drawLine(
        Offset(x, center - barHeight / 2),
        Offset(x, center + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.levels != levels;
}
