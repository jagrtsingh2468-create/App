import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/voice_effects.dart';
import '../../core/error/failures.dart';
import '../providers/recorder_provider.dart';
import '../providers/theme_provider.dart';
import 'library_screen.dart';
import 'record_screen.dart';
import 'settings_screen.dart';

/// App entry screen. Big hero header, two primary actions
/// (record / import), a horizontal quick-effects row, and an easter egg
/// tucked behind a long-press on the logo.
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
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showEasterEgg(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✨ Jagrit Productions'),
        content: const Text('Built with care, one commit at a time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

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
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () => _showEasterEgg(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.seed.withValues(alpha: 0.9),
                        AppColors.accent.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transform your\nvoice in seconds',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Record or import audio, then apply fun effects like Robot, Helium, and Deep Voice.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
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
              const SizedBox(height: 32),
              Text(
                'Quick Effects',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kVoiceEffects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final effect = kVoiceEffects[i];
                    return _QuickEffectChip(effect: effect);
                  },
                ),
              ),
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
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
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

class _QuickEffectChip extends StatelessWidget {
  final VoiceEffect effect;

  const _QuickEffectChip({required this.effect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(effect.icon, color: AppColors.accent, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            effect.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
