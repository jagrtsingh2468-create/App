import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../providers/challenge_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/live_waveform_widget.dart';
import '../widgets/save_recording_sheet.dart';
import '../widgets/waveform_widget.dart';
import '../../core/constants/app_strings.dart';

/// Reverse Challenge: record (or import) a phrase, hear it played
/// backwards, try to say that reversed sound back convincingly, then hear
/// your attempt reversed again — the "reveal". A playful game built
/// entirely from pieces the app already has (recording, importing,
/// areverse via applyCustomFilter, the shared player, and the
/// interactive save sheet).
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _isPlayingSub;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChallengeProvider>();
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
    context.read<ChallengeProvider>().stopPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reverse Challenge'),
        actions: [
          if (provider.stage != ChallengeStage.idle)
            IconButton(
              tooltip: 'Start over',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                provider.stopPlayback();
                provider.reset();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.stage != ChallengeStage.idle)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _StepDots(currentStep: _stepIndexFor(provider.stage)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(provider.stage),
                    child: _buildForStage(context, provider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _stepIndexFor(ChallengeStage stage) {
    switch (stage) {
      case ChallengeStage.idle:
      case ChallengeStage.recordingOriginal:
      case ChallengeStage.processingOriginal:
        return 0;
      case ChallengeStage.readyToMimic:
      case ChallengeStage.recordingMimic:
      case ChallengeStage.processingMimic:
        return 1;
      case ChallengeStage.result:
        return 2;
    }
  }

  Widget _buildForStage(BuildContext context, ChallengeProvider provider) {
    switch (provider.stage) {
      case ChallengeStage.idle:
        return _IntroStep(
          onStart: provider.startRecordingOriginal,
          onImport: provider.importOriginal,
        );
      case ChallengeStage.recordingOriginal:
        return _RecordingStep(
          title: 'Say a phrase...',
          subtitle: 'Anything you like — a sentence, a tongue twister, your name.',
          amplitudeStream: provider.amplitudeStream,
          onStop: provider.stopRecordingOriginal,
        );
      case ChallengeStage.processingOriginal:
        return const _ProcessingStep(label: 'Reversing your phrase...');
      case ChallengeStage.readyToMimic:
        return _ReadyToMimicStep(
          provider: provider,
          position: _position,
          isPlaying: _isPlaying,
        );
      case ChallengeStage.recordingMimic:
        return _RecordingStep(
          title: 'Say it back!',
          subtitle: 'Try to recreate the backwards sound you just heard.',
          amplitudeStream: provider.amplitudeStream,
          onStop: provider.stopRecordingMimic,
        );
      case ChallengeStage.processingMimic:
        return const _ProcessingStep(label: 'Revealing your result...');
      case ChallengeStage.result:
        return _ResultStep(provider: provider, isPlaying: _isPlaying);
    }
  }
}

class _StepDots extends StatelessWidget {
  final int currentStep; // 0, 1, or 2
  const _StepDots({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = ['Record', 'Mimic', 'Reveal'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 14 : 10,
                height: isActive ? 14 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (isActive || isDone)
                      ? const LinearGradient(colors: [AppColors.seed, AppColors.accent])
                      : null,
                  color: (isActive || isDone) ? null : Theme.of(context).colorScheme.surfaceContainerHigh,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? AppColors.seed
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _IntroStep extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onImport;
  const _IntroStep({required this.onStart, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔄', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 24),
        Text(
          'Can you say it backwards?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          "Record or import a phrase, we'll reverse it, and you try to mimic "
          "the reversed sound. Then we reverse your attempt back — see how "
          "close you get!",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        _GradientButton(
          icon: Icons.mic_rounded,
          label: 'Record a Phrase',
          onTap: onStart,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onImport,
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Import Audio Instead'),
        ),
      ],
    );
  }
}

class _RecordingStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final Stream<double> amplitudeStream;
  final VoidCallback onStop;

  const _RecordingStep({
    required this.title,
    required this.subtitle,
    required this.amplitudeStream,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        LiveWaveformWidget(amplitudeStream: amplitudeStream, isActive: true),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onStop,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent,
              boxShadow: [
                BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.stop_rounded, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 12),
        Text('Tap to stop', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProcessingStep extends StatelessWidget {
  final String label;
  const _ProcessingStep({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ReadyToMimicStep extends StatelessWidget {
  final ChallengeProvider provider;
  final Duration position;
  final bool isPlaying;

  const _ReadyToMimicStep({
    required this.provider,
    required this.position,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Listen closely...',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          "That's your phrase, reversed. Try to say back exactly what you just heard.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              WaveformWidget(
                filePath: provider.reversedChallengePath!,
                currentPosition: position,
              ),
              const SizedBox(height: 12),
              IconButton.filled(
                iconSize: 32,
                onPressed: () {
                  if (isPlaying) {
                    provider.pausePlayback();
                  } else {
                    provider.playClip(provider.reversedChallengePath!);
                  }
                },
                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
              const SizedBox(height: 4),
              Text(
                isPlaying ? 'Playing...' : 'Tap to listen again as many times as you like',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _GradientButton(
          icon: Icons.mic_rounded,
          label: 'Record Your Attempt',
          onTap: () {
            provider.stopPlayback();
            provider.startRecordingMimic();
          },
        ),
      ],
    );
  }
}

class _ResultStep extends StatefulWidget {
  final ChallengeProvider provider;
  final bool isPlaying;
  const _ResultStep({required this.provider, required this.isPlaying});

  @override
  State<_ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<_ResultStep> {
  String? _activeClip;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('🎉', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          "Here's your reveal!",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare your reveal to the original phrase.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        _ClipCard(
          label: 'Original phrase',
          emoji: '🗣️',
          isActive: _activeClip == provider.originalPath,
          isPlaying: widget.isPlaying && _activeClip == provider.originalPath,
          onTap: () {
            setState(() => _activeClip = provider.originalPath);
            if (widget.isPlaying && _activeClip == provider.originalPath) {
              provider.pausePlayback();
            } else {
              provider.playClip(provider.originalPath!);
            }
          },
        ),
        const SizedBox(height: 12),
        _ClipCard(
          label: 'Your reveal',
          emoji: '⏪',
          isActive: _activeClip == provider.revealPath,
          isPlaying: widget.isPlaying && _activeClip == provider.revealPath,
          onTap: () {
            setState(() => _activeClip = provider.revealPath);
            if (widget.isPlaying && _activeClip == provider.revealPath) {
              provider.pausePlayback();
            } else {
              provider.playClip(provider.revealPath!);
            }
          },
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.stopPlayback();
                  provider.reset();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry', overflow: TextOverflow.visible, softWrap: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => _saveReveal(context, provider),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Reveal'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveReveal(BuildContext context, ChallengeProvider provider) async {
    final saved = await showSaveRecordingSheet(
      context,
      emoji: '🔄',
      defaultTitle: 'Reverse Challenge',
      onSave: provider.saveReveal,
      errorMessage: () => provider.errorMessage,
    );
    if (!mounted) return;

    if (saved != null) {
      if (mounted) context.read<LibraryProvider>().loadRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.savedSuccess)),
      );
    }
  }
}

class _ClipCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;

  const _ClipCard({
    required this.label,
    required this.emoji,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.seed, AppColors.accent]),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                size: 36,
                color: AppColors.seed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [AppColors.seed, AppColors.accent]),
          boxShadow: [
            BoxShadow(color: AppColors.seed.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
