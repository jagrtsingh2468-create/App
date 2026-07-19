import 'package:flutter/material.dart';
import '../../core/constants/voice_effects.dart';

/// A single tappable effect tile in the effects grid. Shows a selected
/// state with a colored border + scale animation so users get immediate
/// feedback on which effect is currently chosen.
class EffectCard extends StatelessWidget {
  final VoiceEffect effect;
  final bool isSelected;
  final bool isProcessing;
  final VoidCallback onTap;

  const EffectCard({
    super.key,
    required this.effect,
    required this.isSelected,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: isSelected ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: isSelected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isProcessing ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(effect.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  effect.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                ),
                if (isSelected && isProcessing) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
