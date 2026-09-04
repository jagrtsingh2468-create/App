import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/editor_provider.dart';
import '../widgets/waveform_widget.dart';

/// Real Editor screen: waveform + pitch/speed/echo/reverb sliders wired to
/// EditorProvider. Sliders auto-trigger a debounced ffmpeg re-render and
/// playback (see EditorProvider._renderPreview) — there's no manual
/// play/pause or Apply button, since the provider doesn't expose those.
/// Shows a small processing indicator while a preview is rendering, and
/// any error message the provider surfaces.
///
/// Assumption: whatever navigates to this screen has already called
/// editorProvider.attachSource(recordingPath) — this screen doesn't set
/// the source itself. Let me know if that's not how it's wired and I'll
/// adjust (e.g. accept the path as a constructor arg and call attachSource
/// in initState).
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editorProvider = context.watch<EditorProvider>();
    final waveformPath = editorProvider.previewPath ?? editorProvider.sourcePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          if (editorProvider.isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (waveformPath == null)
                const Expanded(
                  child: Center(child: Text('No recording selected')),
                )
              else ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: WaveformWidget(
                      filePath: waveformPath,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (editorProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      editorProvider.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),

                Expanded(
                  child: ListView(
                    children: [
                      _EditorSlider(
                        label: 'Pitch',
                        icon: Icons.graphic_eq,
                        value: editorProvider.pitch,
                        min: -0.5,
                        max: 0.5,
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
              ],
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