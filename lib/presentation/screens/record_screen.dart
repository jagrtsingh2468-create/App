import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../providers/recorder_provider.dart';
import '../widgets/animated_record_button.dart';
import 'effects_screen.dart';

/// Handles live microphone capture. Once a recording is stopped (or the
/// user arrived here with an imported file already set), it automatically
/// advances to [EffectsScreen] for effect selection.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  @override
  void initState() {
    super.initState();
    // If we arrived here with an already-imported file, skip straight to
    // the effects screen instead of showing the record button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecorderProvider>();
      if (provider.stage == RecorderStage.sourceReady) {
        _goToEffects();
      }
    });
  }

  void _goToEffects() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const EffectsScreen()),
    );
  }

  Future<void> _handleTap(RecorderProvider provider) async {
    if (provider.stage == RecorderStage.recording) {
      await provider.stopRecording();
      if (provider.stage == RecorderStage.sourceReady && mounted) {
        _goToEffects();
      }
    } else {
      await provider.startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record')),
      body: Consumer<RecorderProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.errorMessage!)),
              );
              provider.clearError();
            });
          }

          final isRecording = provider.stage == RecorderStage.recording;

          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isRecording
                          ? AppStrings.recordListening
                          : AppStrings.recordTapToStart,
                      key: ValueKey(isRecording),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 48),
                  AnimatedRecordButton(
                    isRecording: isRecording,
                    onTap: () => _handleTap(provider),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    isRecording ? AppStrings.recordTapToStop : '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
