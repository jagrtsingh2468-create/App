import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/recording.dart';

/// Shows an interactive bottom sheet for naming and saving a processed
/// clip: a gradient avatar (emoji of your choosing), a name field, and a
/// full-width gradient button that morphs through idle -> saving -> saved
/// states in place, instead of a plain AlertDialog with a static button.
///
/// Generic over whatever produced the clip (an Effects preview, a
/// Reverse Studio preview, etc) — the caller supplies [emoji],
/// [defaultTitle], the actual [onSave] action, and how to read back an
/// error message if it fails, rather than this sheet depending on any
/// one provider type.
///
/// Returns the saved [Recording] on success, or null if the user
/// cancelled or the save failed (in which case [errorMessage] should
/// return the caller's failure reason for this sheet to show inline).
Future<Recording?> showSaveRecordingSheet(
  BuildContext context, {
  required String emoji,
  required String defaultTitle,
  required Future<Recording?> Function(String title) onSave,
  required String? Function() errorMessage,
}) {
  return showModalBottomSheet<Recording?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SaveRecordingSheet(
      emoji: emoji,
      defaultTitle: defaultTitle,
      onSave: onSave,
      errorMessage: errorMessage,
    ),
  );
}

enum _SaveState { idle, saving, saved }

class _SaveRecordingSheet extends StatefulWidget {
  final String emoji;
  final String defaultTitle;
  final Future<Recording?> Function(String title) onSave;
  final String? Function() errorMessage;

  const _SaveRecordingSheet({
    required this.emoji,
    required this.defaultTitle,
    required this.onSave,
    required this.errorMessage,
  });

  @override
  State<_SaveRecordingSheet> createState() => _SaveRecordingSheetState();
}

class _SaveRecordingSheetState extends State<_SaveRecordingSheet> {
  late final TextEditingController _controller;
  _SaveState _state = _SaveState.idle;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _state != _SaveState.idle) return;

    setState(() {
      _state = _SaveState.saving;
      _error = null;
    });

    final saved = await widget.onSave(title);

    if (!mounted) return;

    if (saved == null) {
      setState(() {
        _state = _SaveState.idle;
        _error = widget.errorMessage() ?? 'Could not save recording.';
      });
      return;
    }

    setState(() => _state = _SaveState.saved);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.seed, AppColors.accent],
                    ),
                  ),
                  child: Center(
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Name your recording',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: _state == _SaveState.idle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: InputDecoration(
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _handleSave(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (_state == _SaveState.idle)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                if (_state == _SaveState.idle) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _SaveButton(state: _state, onTap: _handleSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final _SaveState state;
  final VoidCallback onTap;

  const _SaveButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDone = state == _SaveState.saved;
    return GestureDetector(
      onTap: state == _SaveState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDone
                ? [Colors.green.shade400, Colors.green.shade600]
                : [AppColors.seed, AppColors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDone ? Colors.green : AppColors.seed).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (state) {
              _SaveState.idle => const Row(
                  key: ValueKey('idle'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Save Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              _SaveState.saving => const SizedBox(
                  key: ValueKey('saving'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
              _SaveState.saved => const Icon(
                  Icons.check_circle_rounded,
                  key: ValueKey('saved'),
                  color: Colors.white,
                  size: 26,
                ),
            },
          ),
        ),
      ),
    );
  }
}
