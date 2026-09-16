import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/voice_effects.dart';
import '../../core/utils/file_utils.dart';
import '../../domain/entities/recording.dart';
import '../providers/editor_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/waveform_widget.dart';

/// Real Editor screen. When no recording is loaded, shows a picker over
/// everything saved in the Library so the user can jump straight in from
/// here instead of only reaching the Editor via Library's "Edit" icon.
/// Once a source is attached, shows the waveform + pitch/speed/echo/reverb
/// sliders wired to EditorProvider (auto-debounced ffmpeg re-render and
/// playback — no manual play/pause or Apply button, since the provider
/// doesn't expose those).
class EditorScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const EditorScreen({super.key, this.onBack});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh the library list on every visit so a recording saved just
    // before switching to this tab shows up in the picker immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LibraryProvider>().loadRecordings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorProvider = context.watch<EditorProvider>();
    final waveformPath = editorProvider.previewPath ?? editorProvider.sourcePath;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
        title: const Text('Editor'),
        actions: [
          if (waveformPath != null)
            IconButton(
              tooltip: 'Choose a different recording',
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: editorProvider.clearSource,
            ),
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
        child: waveformPath == null
            ? const _RecordingPicker()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                ),
              ),
      ),
    );
  }
}

/// Lets the user pick any saved recording to load straight into the
/// Editor's sliders, mirroring the Library list's look.
class _RecordingPicker extends StatelessWidget {
  const _RecordingPicker();

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();

    if (library.isLoading && library.recordings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (library.recordings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing to edit yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Record or save a voice clip first, then pick it here to fine-tune pitch, speed, echo, and reverb.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Pick a recording to edit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: library.loadRecordings,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: library.recordings.length,
              itemBuilder: (context, index) {
                final recording = library.recordings[index];
                return _PickerTile(
                  recording: recording,
                  onTap: () => context.read<EditorProvider>().attachSource(recording.filePath),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final Recording recording;
  final VoidCallback onTap;

  const _PickerTile({required this.recording, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effect = voiceEffectFor(recording.appliedEffect);
    final dateLabel = DateFormat('MMM d, h:mm a').format(recording.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(effect?.emoji ?? '🎙️', style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${effect == null ? 'Original' : effect.label} · ${FileUtils.humanDuration(recording.duration)} · $dateLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.tune_rounded, color: scheme.onSurfaceVariant),
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
