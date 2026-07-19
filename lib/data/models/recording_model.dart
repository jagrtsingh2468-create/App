import '../../core/constants/voice_effects.dart';
import '../../domain/entities/recording.dart';

/// Data-layer representation of [Recording] that knows how to convert
/// to/from the JSON stored in SharedPreferences. The domain layer never
/// sees this class directly - only the repository implementation does.
class RecordingModel extends Recording {
  const RecordingModel({
    required super.id,
    required super.filePath,
    required super.title,
    required super.createdAt,
    required super.duration,
    required super.fileSizeBytes,
    super.appliedEffect,
  });

  factory RecordingModel.fromEntity(Recording r) => RecordingModel(
        id: r.id,
        filePath: r.filePath,
        title: r.title,
        createdAt: r.createdAt,
        duration: r.duration,
        fileSizeBytes: r.fileSizeBytes,
        appliedEffect: r.appliedEffect,
      );

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      fileSizeBytes: json['fileSizeBytes'] as int,
      appliedEffect: VoiceEffectType.values[json['appliedEffect'] as int],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'fileSizeBytes': fileSizeBytes,
        'appliedEffect': appliedEffect.index,
      };
}
