import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/voice_effects.dart';
import '../providers/recorder_provider.dart';
import '../widgets/effect_card.dart';
import '../widgets/waveform_widget.dart';
import '../widgets/save_recording_sheet.dart';

/// Lets the user pick a voice effect, preview the result, and save it.
/// This is the screen most of the app's "magic" is visible on.
class EffectsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const EffectsScreen({super.key, this.onBack});

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecorderProvider>();

    return Scaffold(
      appBar: AppBar(leading: widget.onBack != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack) : null, title: const Text(AppStrings.chooseEffect)),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.stage == RecorderStage.previewReady ||
                provider.stage == RecorderStage.saving)
              _PreviewPlayer(
                provider: provider,
                position: _position,
                duration: _duration,
                isPlaying: _isPlaying,
                onPositionUpdate: (p) => setState(() => _position = p),
                onDurationUpdate: (d) => setState(() => _duration = d),
                onPlayingUpdate: (p) => setState(() => _isPlaying = p),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: kVoiceEffects.length + 1, // +1 for "Original"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _OriginalCard(provider: provider);
                  }
                  final effect = kVoiceEffects[index - 1];
                  final isSelected = provider.selectedEffect == effect.type;
                  return EffectCard(
                    effect: effect,
                    isSelected: isSelected,
                    isProcessing: provider.stage == RecorderStage.processing,
                    onTap: () => provider.selectEffect(effect.type),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: provider.stage == RecorderStage.previewReady
          ? FloatingActionButton.extended(
              onPressed: () => _showSaveSheet(context, provider),
              icon: const Icon(Icons.save_rounded),
              label: const Text(AppStrings.saveRecording),
            )
          : null,
    );
  }

  Future<void> _showSaveSheet(
    BuildContext context,
    RecorderProvider provider,
  ) async {
    final saved = await showSaveRecordingSheet(context, provider);
    if (!mounted) return;

    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.savedSuccess)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

/// Special first grid tile that resets back to the unprocessed source audio.
class _OriginalCard extends StatelessWidget {
  final RecorderProvider provider;
  const _OriginalCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return EffectCard(
      effect: const VoiceEffect(
        type: VoiceEffectType.none,
        label: 'Original',
        emoji: '🎙️',
        description: 'No effect',
        ffmpegFilter: '',
      ),
      isSelected: provider.selectedEffect == VoiceEffectType.none &&
          provider.previewPath != null,
      isProcessing: provider.stage == RecorderStage.processing,
      onTap: () => provider.selectEffect(VoiceEffectType.none),
    );
  }
}

class _PreviewPlayer extends StatefulWidget {
  final RecorderProvider provider;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final ValueChanged<Duration> onPositionUpdate;
  final ValueChanged<Duration> onDurationUpdate;
  final ValueChanged<bool> onPlayingUpdate;

  const _PreviewPlayer({
    required this.provider,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPositionUpdate,
    required this.onDurationUpdate,
    required this.onPlayingUpdate,
  });

  @override
  State<_PreviewPlayer> createState() => _PreviewPlayerState();
}

class _PreviewPlayerState extends State<_PreviewPlayer> {
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _isPlayingSub;

  @override
  void initState() {
    super.initState();
    _positionSub = widget.provider.positionStream.listen(widget.onPositionUpdate);
    _durationSub = widget.provider.durationStream.listen(widget.onDurationUpdate);
    _isPlayingSub = widget.provider.isPlayingStream.listen(widget.onPlayingUpdate);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _isPlayingSub?.cancel();
    // Stop the preview so audio doesn't keep playing in the background
    // after this screen (or this player card) goes away.
    widget.provider.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
      WaveformWidget(
        filePath: widget.provider.previewPath ?? '',
        currentPosition: widget.position,
      ),
          const SizedBox(height: 12),
          IconButton.filled(
            iconSize: 32,
            onPressed: () {
              if (widget.isPlaying) {
                widget.provider.pausePreview();
              } else {
                widget.provider.playPreview();
              }
            },
            icon: Icon(
              widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
