import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EditorPlaceholderScreen extends StatelessWidget {
  const EditorPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Editor')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.seed, AppColors.accent]),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Editor coming soon',
              Text(
                'Editor coming soon',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Waveform view, pitch, speed, echo and reverb controls with fast preview are on the way.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
