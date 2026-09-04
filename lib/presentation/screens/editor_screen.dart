import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/editor_provider.dart';
import '../widgets/waveform_widget.dart';

/// Real Editor screen: waveform + pitch/speed/echo/reverb sliders,
/// wired live to EditorProvider, with a play/pause preview button.
///
/// Assumption: EditorProvider exposes filePath, pitch, speed, echo, reverb
/// (doubles) plus setters (setPitch/setSpeed/setEcho/setReverb) and an
/// isPlaying bool + togglePlayback() method. Adjust names below if yours
/// differ — the structure will still hold.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editorProvider = context.watch<EditorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Editor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Waveform
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: WaveformWidget(
                    filePath: editorProvider.filePath,
                    height: 100,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Play / pause preview
              Center(
                child: IconButton.filled(
                  iconSize: 40,
                  icon: Icon(
                    editorProvider.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: editorProvider.togglePlayback,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    _EditorSlider(
                      label: 'Pitch',
                      icon: Icons.graphic_eq,
                      value: editorProvider.pitch,
                      min: 0.5,
                      max: 2.0,
                      onChanged: editorProvider.setPitch,
                    ),
                    _EditorSlider(
                      label: 'Speed',
                      icon: Icons.speed,
                      value: editorProvider.speed,
                      min: 0.5,
                      max: 2.0,
                      onChanged: editorProvider.setSpeed,
                    ),
                    _EditorSlider(
                      label: 'Echo',
                      icon: Icons.surround_sound,
                      value: editorProvider.echo,
                      min: 0.0,
                      max: 1.0,
                      onChanged: editorProvider.setEcho,
                    ),
                    _EditorSlider(
                      label: 'Reverb',
                      icon: Icons.blur_on,
                      value: editorProvider.reverb,
                      min: 0.0,
                      max: 1.0,
                      onChanged: editorProvider.setReverb,
                    ),
                  ],
                ),
              ),

              // Apply button
              FilledButton.icon(
                onPressed: () => editorProvider.applyCustomFilter(),
                icon: const Icon(Icons.check),
                label: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _EditorSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(value.toStringAsFixed(2)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
