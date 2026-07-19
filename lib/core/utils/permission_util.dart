import 'package:permission_handler/permission_handler.dart';
import '../error/failures.dart';

/// Centralizes every runtime permission request the app needs.
///
/// Android version matters a lot here:
/// - Android 8-12 (API 26-32): legacy READ/WRITE_EXTERNAL_STORAGE
/// - Android 13+ (API 33+): scoped READ_MEDIA_AUDIO instead
/// `permission_handler`'s [Permission.audio] / [Permission.storage] map to
/// the right one automatically per-OS, so we don't need to branch on SDK
/// version manually here.
class PermissionUtil {
  PermissionUtil._();

  /// Requests microphone access. Throws [PermissionFailure] if denied.
  static Future<void> ensureMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw const PermissionFailure(
        'Microphone permission is required to record audio.',
      );
    }
  }

  /// Requests storage/media access needed to import files.
  /// Not required for saving into the app's own private directory, only
  /// for reading arbitrary files the user picks via the system file picker.
  static Future<void> ensureStoragePermission() async {
    final status = await Permission.audio.request();
    if (!status.isGranted) {
      // Fall back to legacy storage permission for older Android versions
      // where Permission.audio may not be applicable.
      final legacy = await Permission.storage.request();
      if (!legacy.isGranted) {
        throw const PermissionFailure(
          'Storage permission is required to import audio files.',
        );
      }
    }
  }

  static Future<bool> isMicrophonePermanentlyDenied() async {
    return Permission.microphone.isPermanentlyDenied;
  }

  static Future<void> openAppSettingsPage() => openAppSettings();
}
