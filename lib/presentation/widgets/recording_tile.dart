import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/voice_effects.dart';
import '../../core/utils/file_utils.dart';
import '../../domain/entities/recording.dart';

/// One row in the "My Recordings" library list.
class RecordingTile extends StatelessWidget {
  final Recording recording;
  final bool isPlaying;
  final VoidCallback onPlayToggle;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const RecordingTile({
    super.key,
    required this.recording,
    required this.isPlaying,
    required this.onPlayToggle,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effect = voiceEffectFor(recording.appliedEffect);
    final dateLabel = DateFormat('MMM d, h:mm a').format(recording.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: onPlayToggle,
              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${effect == null ? 'Original' : '${effect.emoji} ${effect.label}'} '
                    '· ${FileUtils.humanDuration(recording.duration)} · $dateLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Share',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
