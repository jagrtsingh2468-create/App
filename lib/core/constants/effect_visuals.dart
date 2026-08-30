import 'package:flutter/material.dart';

/// Accent color per effect — drives the glow + gradient icon look.
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
  'bassBoost': Color(0xFF66BB6A),
  'glitch': Color(0xFFEF476F),
};

/// Glowing gradient-tinted icon used on the effect picker.
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
      ..moveTo(w * 0.5, h * 0.02)
      ..cubicTo(w * 0.12, h * 0.02, w * 0.06, h * 0.55, w * 0.28, h * 0.88)
      ..cubicTo(w * 0.40, h * 1.02, w * 0.60, h * 1.02, w * 0.72, h * 0.88)
      ..cubicTo(w * 0.94, h * 0.55, w * 0.88, h * 0.02, w * 0.5, h * 0.02)
      ..close();

    final clear = Paint()..blendMode = BlendMode.clear;
eof
