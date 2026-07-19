/// All user-visible copy in one file. Keeping strings out of widgets makes
/// a future move to Flutter's `intl` localization a mechanical change
/// instead of a hunt through the whole codebase.
class AppStrings {
  AppStrings._();

  static const appName = 'Voice Changer';
  static const homeTitle = 'Voice Changer';
  static const libraryTitle = 'My Recordings';

  static const recordTapToStart = 'Tap to start recording';
  static const recordTapToStop = 'Tap to stop';
  static const recordListening = 'Listening…';

  static const importAudio = 'Import Audio File';
  static const chooseEffect = 'Choose an Effect';
  static const applyingEffect = 'Applying effect…';
  static const noEffect = 'Original (No Effect)';

  static const saveRecording = 'Save';
  static const shareRecording = 'Share';
  static const deleteRecording = 'Delete';
  static const deleteConfirmTitle = 'Delete recording?';
  static const deleteConfirmBody =
      'This will permanently remove this audio file from your device.';
  static const cancel = 'Cancel';

  static const emptyLibraryTitle = 'No recordings yet';
  static const emptyLibrarySubtitle =
      'Record your voice or import a file to get started.';

  static const micPermissionDenied =
      'Microphone permission is required to record audio.';
  static const storagePermissionDenied =
      'Storage permission is required to import or save audio files.';
  static const openSettings = 'Open Settings';

  static const genericError = 'Something went wrong. Please try again.';
  static const processingFailed = 'Could not apply the effect to this audio.';
  static const savedSuccess = 'Saved to your recordings.';
}
