import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/recorder_provider.dart';
import 'effects_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'record_screen.dart';
import 'editor_placeholder_screen.dart';

/// Persistent bottom-nav shell wrapping the app's 5 main destinations.
/// Uses [IndexedStack] so switching tabs preserves each screen's state
/// (scroll position, in-progress edits, etc) instead of rebuilding it.
class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    LibraryScreen(),
    RecordScreen(),
    EffectsScreen(),
    EditorPlaceholderScreen(),
  ];

  void _onTap(int i) {
    if (i == 2) {
      context.read<RecorderProvider>().reset();
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomAppBar(
        color: scheme.surfaceContainerHigh, elevation: 16, shadowColor: AppColors.seed,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _index == 0,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: Icons.library_music_rounded,
                label: 'Library',
                selected: _index == 1,
                onTap: () => _onTap(1),
              ),
              _MicNavItem(
                selected: _index == 2,
                onTap: () => _onTap(2),
              ),
              _NavItem(
                icon: Icons.graphic_eq_rounded,
                label: 'Effects',
                selected: _index == 3,
                onTap: () => _onTap(3),
              ),
              _NavItem(
                icon: Icons.tune_rounded,
                label: 'Editor',
                selected: _index == 4,
                onTap: () => _onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicNavItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _MicNavItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.seed, AppColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.seed.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
