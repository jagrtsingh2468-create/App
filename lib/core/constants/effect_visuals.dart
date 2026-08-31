import 'package:flutter/material.dart';

const Map<String, Color> kEffectColors = {
  'none': Color(0xFF64B5F6),
  'deepVoice': Color(0xFFBA68C8),
  'robot': Color(0xFF66BB6A),
  'echo': Color(0xFFEF5350),
  'reverb': Color(0xFF5C9CE6),
  'alien': Color(0xFF66BB6A),
  'helium': Color(0xFFFFA726),
  'slowMotion': Color(0xFFAB47BC),
  'fastVoice': Color(0xFFFF7043),
  'babyVoice': Color(0xFFEC609F),
  'drunkVoice': Color(0xFFD4A017),
  'underwater': Color(0xFF42A5F5),
  'fairy': Color(0xFFE91E8C),
  'autotune': Color(0xFF26C6DA),
  'chorusDoubler': Color(0xFF7E57C2),
  'bassBoost': Color(0xFF29B6F6),
  'glitch': Color(0xFFEF476F),
};

class GlowIcon extends StatelessWidget {
  final String effectId;
  final IconData icon;
  final double size;

  const GlowIcon({
    super.key,
    required this.effectId,
    required this.icon,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final color = kEffectColors[effectId] ?? const Color(0xFF9E9E9E);

    if (effectId == 'alien') {
      return _glowWrap(
        color,
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _AlienPainter(color)),
        ),
      );
    }

    return _glowWrap(
      color,
      ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.95), color.withOpacity(0.55)],
        ).createShader(bounds),
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }

  Widget _glowWrap(Color color, Widget child) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.45), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

class _AlienPainter extends CustomPainter {
  final Color color;
  _AlienPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint()..color = color;

    final head = Path()
      ..moveTo(w * 0.5, h * 0.0)
      ..cubicTo(w * 0.14, h * 0.0, w * 0.03, h * 0.42, w * 0.20, h * 0.74)
      ..cubicTo(w * 0.30, h * 0.94, w * 0.70, h * 0.94, w * 0.80, h * 0.74)
      ..cubicTo(w * 0.97, h * 0.42, w * 0.86, h * 0.0, w * 0.5, h * 0.0)
      ..close();

    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawPath(head, fill);
    _almondEye(canvas, Offset(w * 0.32, h * 0.42), w * 0.155, h * 0.24, -0.45, clear);
    _almondEye(canvas, Offset(w * 0.68, h * 0.42), w * 0.155, h * 0.24, 0.45, clear);
    canvas.restore();
  }

  void _almondEye(Canvas canvas, Offset c, double rx, double ry, double angle, Paint p) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AlienPainter oldDelegate) => oldDelegate.color != color;
}
