import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/audio_repository_impl.dart';
import 'domain/repositories/audio_repository.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/providers/recorder_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  // Catch and log any uncaught Flutter framework errors instead of letting
  // them crash silently in release builds.
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runApp(const VoiceChangerApp());
}

/// Root widget. Sets up dependency injection (one shared [AudioRepository]
/// instance feeding both [RecorderProvider] and [LibraryProvider]) and the
/// light/dark [MaterialApp] theming.
class VoiceChangerApp extends StatelessWidget {
  const VoiceChangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Single repository instance shared across the whole app so the
        // recorder and library features stay in sync (e.g. same audio
        // player under the hood).
        Provider<AudioRepository>(
          create: (_) => AudioRepositoryImpl(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AudioRepository, RecorderProvider>(
          create: (context) => RecorderProvider(context.read<AudioRepository>()),
          update: (context, repo, previous) => previous ?? RecorderProvider(repo),
        ),
        ChangeNotifierProxyProvider<AudioRepository, LibraryProvider>(
          create: (context) => LibraryProvider(context.read<AudioRepository>()),
          update: (context, repo, previous) => previous ?? LibraryProvider(repo),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Voice Changer',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.mode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
