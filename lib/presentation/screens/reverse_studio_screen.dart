import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/voice_effects.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/file_utils.dart';
import '../../domain/entities/recording.dart';
import '../providers/library_provider.dart';
import '../providers/reverse_provider.dart';
import '../widgets/save_recording_sheet.dart';
import '../widgets/waveform_widget.dart';

/// Reverse Studio: pick a saved recording, play it backwards, and save
/// the result. Reuses the same recording-picker and interactive-save
/// patterns as the Editor and Effects screens, but is reached from
/// Home's app bar rather than the bottom nav, since it's a standalone
/// pushed screen (its own back button pops normally).
class ReverseStudioScreen extends StatefulWidget {
  const ReverseStudioScreen({super.key});

  @override
  State<ReverseStudioScreen> createState() => _ReverseStudioScreenState();
}

class _ReverseStudioScreenState extends State<ReverseStudioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LibraryProvider>().loadRecordings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reverseProvider = context.watch<ReverseProvider>();
    final hasSource = reverseProvider.sourcePath != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reverse Studio'),
        actions: [
          if (hasSource)
            IconButton(
              tooltip: 'Choose a different recording',
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: reverseProvider.clearSource,
            ),
        ],
      ),
      body: SafeArea(
        child: hasSource ? const _ReversePreview() : const _RecordingPicker(),
      ),
    );
  }
}

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
                Icons.fast_rewind_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing to reverse yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Record or save a voice clip first, then pick it here to play it backwards.',
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
            'Pick a recording to reverse',
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
                  onTap: () => context.read<ReverseProvider>().attachSource(recording.filePath),
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
              Icon(Icons.fast_rewind_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReversePreview extends StatefulWidget {
  const _ReversePreview();

  @override
  State<_ReversePreview> createState() => _ReversePreviewState();
}

class _ReversePreviewState extends State<_ReversePreview> {
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _isPlayingSub;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ReverseProvider>();
    _positionSub = provider.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _isPlayingSub = provider.isPlayingStream.listen((p) {
      if (mounted) setState(() => _isPlaying = p);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _isPlayingSub?.cancel();
    context.read<ReverseProvider>().stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReverseProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                if (provider.isProcessing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Reversing...'),
                      ],
                    ),
                  )
                else if (provider.previewPath != null) ...[
                  WaveformWidget(
                    filePath: provider.previewPath!,
                    currentPosition: _position,
                  ),
                  const SizedBox(height: 12),
                  IconButton.filled(
                    iconSize: 32,
                    onPressed: () {
                      if (_isPlaying) {
                        provider.pausePreview();
                      } else {
                        provider.playPreview();
                      }
                    },
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                ],
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      provider.errorMessage!,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (provider.previewPath != null)
            FilledButton.icon(
              onPressed: () => _showSaveSheet(context, provider),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Recording'),
            ),
        ],
      ),
    );
  }

  Future<void> _showSaveSheet(BuildContext context, ReverseProvider provider) async {
    final saved = await showSaveRecordingSheet(
      context,
      emoji: '⏪',
      defaultTitle: 'Reversed Voice',
      onSave: provider.save,
      errorMessage: () => provider.errorMessage,
    );
    if (!mounted) return;

    if (saved != null) {
      if (mounted) context.read<LibraryProvider>().loadRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.savedSuccess)),
      );
      provider.clearSource();
    }
  }
}
