import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/error/failures.dart';
import '../providers/recorder_provider.dart';
import '../providers/theme_provider.dart';
import 'library_screen.dart';
import 'record_screen.dart';

/// App entry screen. Two big primary actions (record / import) plus quick
/// access to the saved-recordings library and the theme toggle.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _importFile(BuildContext context) async {
    final provider = context.read<RecorderProvider>();
    provider.reset();
    try {
      final path = await provider.importFileAndReturnPath();
      if (path != null) {
        provider.setImportedSource(path);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecordScreen()),
          );
        }
      } else if (provider.errorMessage != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
      }
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: [
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: () => themeProvider.toggleDark(!isDark),
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          IconButton(
            tooltip: AppStrings.libraryTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LibraryScreen()),
            ),
            icon: const Icon(Icons.library_music_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Transform your\nvoice in seconds',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record or import audio, then apply fun effects '
                'like Robot, Helium, and Deep Voice.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),
              _PrimaryActionCard(
                icon: Icons.mic_rounded,
                title: 'Record Voice',
                subtitle: 'Capture audio from your microphone',
                onTap: () {
                  context.read<RecorderProvider>().reset();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecordScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _PrimaryActionCard(
                icon: Icons.folder_open_rounded,
                title: AppStrings.importAudio,
                subtitle: 'Pick an existing audio file to transform',
                onTap: () => _importFile(context),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
