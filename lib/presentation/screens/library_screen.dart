import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/recording.dart';
import '../providers/library_provider.dart';
import '../widgets/recording_tile.dart';

/// "My Recordings" screen: lists everything the user has saved, with
/// play/share/delete actions per item.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on every visit so a recording saved just before navigating
    // here always shows up immediately, without needing a manual pull.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadRecordings();
    });
  }


  Future<void> _confirmDelete(
    BuildContext context,
    LibraryProvider provider,
    Recording recording,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteConfirmTitle),
        content: const Text(AppStrings.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.deleteRecording),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.delete(recording);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.libraryTitle)),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.errorMessage!)),
              );
              provider.clearError();
            });
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.recordings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_off_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.emptyLibraryTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.emptyLibrarySubtitle,
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

          return RefreshIndicator(
            onRefresh: provider.loadRecordings,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.recordings.length,
              itemBuilder: (context, index) {
                final recording = provider.recordings[index];
                return RecordingTile(
                  recording: recording,
                  isPlaying: provider.playingId == recording.id,
                  onPlayToggle: () => provider.togglePlay(recording),
                  onShare: () => provider.share(recording),
                  onDelete: () => _confirmDelete(context, provider, recording),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
