import 'package:flutter/material.dart';

/// Big circular record button. Pulses with an expanding ring animation
/// while [isRecording] is true, giving clear visual feedback that the mic
/// is live without needing extra text.
class AnimatedRecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;

  const AnimatedRecordButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  @override
  State<AnimatedRecordButton> createState() => _AnimatedRecordButtonState();
}

class _AnimatedRecordButtonState extends State<AnimatedRecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.isRecording ? Colors.redAccent : scheme.primary;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isRecording)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return _PulseRing(
                    progress: _controller.value,
                    color: color,
                  );
                },
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: widget.isRecording ? 96 : 120,
              height: widget.isRecording ? 96 : 120,
              decoration: BoxDecoration(
                color: color,
                shape: widget.isRecording ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: widget.isRecording
                    ? BorderRadius.circular(20)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: widget.isRecording ? 36 : 52,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double progress;
  final Color color;

  const _PulseRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final size = 120 + (60 * progress);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity * 0.6),
          width: 3,
        ),
      ),
    );
  }
}
