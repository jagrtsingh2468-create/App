import '../../core/constants/voice_effects.dart';

/// Pure domain entity - has no knowledge of files, ffmpeg, or Flutter
/// widgets. This is what use cases and providers pass around; the data
/// layer is responsible for turning it into/from a stored file + metadata.
class Recording {
  final String id;
  final String filePath;
  final String title;
  final DateTime createdAt;
  final Duration duration;
  final int fileSizeBytes;
  final VoiceEffectType appliedEffect;

  const Recording({
    required this.id,
    required this.filePath,
    required this.title,
    required this.createdAt,
    required this.duration,
    required this.fileSizeBytes,
    this.appliedEffect = VoiceEffectType.none,
  });

  Recording copyWith({
    String? filePath,
    String? title,
    Duration? duration,
    int? fileSizeBytes,
    VoiceEffectType? appliedEffect,
  }) {
    return Recording(
      id: id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      createdAt: createdAt,
      duration: duration ?? this.duration,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      appliedEffect: appliedEffect ?? this.appliedEffect,
    );
  }
}
