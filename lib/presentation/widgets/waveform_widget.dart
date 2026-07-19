import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/file_utils.dart';

/// Lightweight stylized waveform + seek bar. Rather than decoding real PCM
/// samples (expensive, and unnecessary for a preview UI), it renders a
/// pleasant pseudo-random bar pattern seeded from the file path so the
/// same clip always looks the same, and highlights bars up to the current
/// playback position.
class WaveformWidget extends StatelessWidget {
  final String seed;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;

  const WaveformWidget({
    super.key,
    required this.seed,
    required this.position,
    required this.duration,
    this.onSeek,
  });

  List<double> _bars() {
    final rand = Random(seed.hashCode);
    return List.generate(40, (_) => 0.25 + rand.nextDouble() * 0.75);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bars = _bars();
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final activeCount = (bars.length * progress).round();

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapDown: onSeek == null
                  ? null
                  : (details) {
                      final ratio =
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                      onSeek!(duration * ratio);
                    },
              child: SizedBox(
                height: 64,
                width: double.infinity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(bars.length, (i) {
                    final active = i < activeCount;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: 64 * bars[i],
                          decoration: BoxDecoration(
                            color: active
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(FileUtils.humanDuration(position),
                style: Theme.of(context).textTheme.bodySmall),
            Text(FileUtils.humanDuration(duration),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
