import 'package:flutter/material.dart';

/// Every voice effect the app supports, plus the exact FFmpeg audio-filter
/// string used to render it. Keeping filters here (instead of scattered
/// through the UI) means adding a new effect later is a one-line change.
///
/// Filter notes:
/// - `asetrate` changes playback sample rate -> shifts pitch AND speed
///   together (classic chipmunk / deep-voice trick), then `aresample`
///   restores a standard output rate so the file stays playable everywhere.
/// - `atempo` changes speed WITHOUT changing pitch (used for slow/fast).
/// - `aecho` adds echo: in_gain:out_gain:delay(ms):decay
/// - Reverb is approximated with chained `aecho` taps (FFmpeg has no
///   built-in convolution reverb without external impulse files).
enum VoiceEffectType {
  none,
  chipmunk,
  deepVoice,
  robot,
  echo,
  reverb,
  alien,
  helium,
  slowMotion,
  fastVoice,
}

class VoiceEffect {
  final VoiceEffectType type;
  final String label;
  final String emoji;
  final IconData icon;
  final String description;
  final String ffmpegFilter;

  const VoiceEffect({
    required this.type,
    required this.label,
    required this.emoji,
    this.icon = Icons.graphic_eq_rounded,
    required this.description,
    required this.ffmpegFilter,
  });
}

/// Master list rendered by the effects grid, in display order.
const List<VoiceEffect> kVoiceEffects = [
  VoiceEffect(
    type: VoiceEffectType.chipmunk,
    label: 'Chipmunk',
    emoji: '🐿️',
    icon: Icons.graphic_eq_rounded,
    description: 'High-pitched, fast and squeaky',
    ffmpegFilter: 'asetrate=44100*1.5,aresample=44100,atempo=0.9',
  ),
  VoiceEffect(
    type: VoiceEffectType.deepVoice,
    label: 'Deep Voice',
    emoji: '🗿',
    icon: Icons.record_voice_over_rounded,
    description: 'Low, slow and powerful',
    ffmpegFilter: 'asetrate=44100*0.7,aresample=44100,atempo=1.1',
  ),
  VoiceEffect(
    type: VoiceEffectType.robot,
    label: 'Robot',
    emoji: '🤖',
    icon: Icons.smart_toy_rounded,
    description: 'Metallic, mechanical tone',
    ffmpegFilter: 'afftdn=nf=-25,vibrato=f=8:d=0.6,aecho=0.8:0.7:20:0.4,atempo=1.0',
  ),
  VoiceEffect(
    type: VoiceEffectType.echo,
    label: 'Echo',
    emoji: '📢',
    icon: Icons.surround_sound_rounded,
    description: 'Repeating fading echo',
    ffmpegFilter: 'aecho=0.8:0.85:500:0.5',
  ),
  VoiceEffect(
    type: VoiceEffectType.reverb,
    label: 'Reverb',
    emoji: '🏛️',
    icon: Icons.account_balance_rounded,
    description: 'Big hall / cathedral space',
    ffmpegFilter: 'aecho=0.8:0.9:40|80|120:0.35|0.25|0.15',
  ),
  VoiceEffect(
    type: VoiceEffectType.alien,
    label: 'Alien',
    emoji: '👽',
    icon: Icons.blur_on_rounded,
    description: 'Wobbly, otherworldly voice',
    ffmpegFilter:
        'asetrate=44100*1.2,aresample=44100,vibrato=f=6:d=0.8,chorus=0.6:0.9:55:0.4:0.25:2',
  ),
  VoiceEffect(
    type: VoiceEffectType.helium,
    label: 'Helium',
    emoji: '🎈',
    icon: Icons.keyboard_double_arrow_up_rounded,
    description: 'Very high, cartoonish pitch',
    ffmpegFilter: 'asetrate=44100*1.8,aresample=44100,atempo=0.85',
  ),
  VoiceEffect(
    type: VoiceEffectType.slowMotion,
    label: 'Slow Motion',
    emoji: '🐢',
    icon: Icons.slow_motion_video_rounded,
    description: 'Slowed down, same pitch',
    ffmpegFilter: 'atempo=0.7',
  ),
  VoiceEffect(
    type: VoiceEffectType.fastVoice,
    label: 'Fast Voice',
    emoji: '🐇',
    icon: Icons.fast_forward_rounded,
    description: 'Sped up, same pitch',
    ffmpegFilter: 'atempo=1.5',
  ),
];

/// Looks up a [VoiceEffect] definition by its enum type.
/// Returns null for [VoiceEffectType.none] (i.e. "no effect applied").
VoiceEffect? voiceEffectFor(VoiceEffectType type) {
  if (type == VoiceEffectType.none) return null;
  return kVoiceEffects.firstWhere((e) => e.type == type);
}
