import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import '../../core/constants/voice_effects.dart';
import '../../core/error/failures.dart';
import '../../core/utils/file_utils.dart';

/// Runs FFmpeg audio-filter graphs (see [kVoiceEffects]) over a source file
/// and produces a new processed file. All processing happens on-device -
/// no audio ever leaves the phone.
class AudioEffectsService {
  /// Applies [effect] to [sourcePath], returning the output file path.
  /// When effect is [VoiceEffectType.none], the file is copied through
  /// unmodified so downstream code always has a fresh, independent file.
  Future<String> apply({
    required String sourcePath,
    required VoiceEffectType effect,
  }) async {
    final outputPath = await FileUtils.newTempPath(extension: 'm4a');

    if (effect == VoiceEffectType.none) {
      await File(sourcePath).copy(outputPath);
      return outputPath;
    }

    final definition = voiceEffectFor(effect);
    if (definition == null) {
      throw const ProcessingFailure('Unknown voice effect selected.');
    }

    // -y            overwrite output without prompting
    // -i            input file
    // -af           audio filter graph (the effect itself)
    // -c:a aac      re-encode to AAC so output stays small & compatible
    final command =
        '-y -i "$sourcePath" -af "${definition.ffmpegFilter}" -c:a aac -b:a 128k "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getFailStackTrace();
      throw ProcessingFailure(
        'FFmpeg failed to apply "${definition.label}" effect. ${logs ?? ''}',
      );
    }

    if (!await File(outputPath).exists()) {
      throw const ProcessingFailure('Effect processing produced no output.');
    }

    return outputPath;
  }

  /// Reads the true duration of an audio file via ffprobe. More reliable
  /// than trusting player metadata, especially right after ffmpeg has
  /// changed a file's effective length (e.g. slow-motion/fast effects).
  Future<Duration> probeDuration(String filePath) async {
    final session = await FFprobeKit.getMediaInformation(filePath);
    final info = session.getMediaInformation();
    final durationStr = info?.getDuration();

    if (durationStr == null) {
      return Duration.zero;
    }

    final seconds = double.tryParse(durationStr) ?? 0.0;
    return Duration(milliseconds: (seconds * 1000).round());
  }
}
