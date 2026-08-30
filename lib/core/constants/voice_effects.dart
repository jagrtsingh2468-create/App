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
  deepVoice,
  robot,
  echo,
  reverb,
  alien,
  helium,
  slowMotion,
  fastVoice,
  babyVoice,
  drunkVoice,
  underwater,
  fairy,
  autotune,
  chorusDoubler,
  bassBoost,
  glitch,
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
    ffmpegFilter: 'asetrate=44100*1.15,aresample=44100,atempo=0.95,aecho=0.5:0.6:20:0.3',
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
  VoiceEffect(
    type: VoiceEffectType.babyVoice,
    label: 'Baby Voice',
    emoji: '👶',
    icon: Icons.child_care_rounded,
    description: 'High, small and playful',
    ffmpegFilter: 'asetrate=44100*1.45,aresample=44100,atempo=0.95',
  ),
  VoiceEffect(
    type: VoiceEffectType.drunkVoice,
    label: 'Drunk Voice',
    emoji: '🥴',
    icon: Icons.sports_bar_rounded,
    description: 'Wobbly pitch and slurred timing',
    ffmpegFilter: 'atempo=0.82,aecho=0.6:0.7:80:0.3',
  ),
  VoiceEffect(
    type: VoiceEffectType.underwater,
    label: 'Underwater',
    emoji: '🫧',
    icon: Icons.water_rounded,
    description: 'Muffled, submerged tone',
    ffmpegFilter: 'lowpass=f=400,asetrate=44100*0.92,aresample=44100,atempo=1.08,tremolo=f=3:d=0.4,aecho=0.5:0.6:25:0.35',
  ),
  VoiceEffect(
    type: VoiceEffectType.fairy,
    label: 'Fairy',
    emoji: '🧚',
    icon: Icons.auto_awesome_rounded,
    description: 'Light, airy and shimmering',
    ffmpegFilter: 'asetrate=44100*1.7,aresample=44100,atempo=0.85,aecho=0.4:0.5:15:0.2',
  ),
  VoiceEffect(
    type: VoiceEffectType.autotune,
    label: 'Autotune-ish',
    emoji: '🎤',
    icon: Icons.tune_rounded,
    description: 'Pitch-snap, robotic-singer feel',
    ffmpegFilter: 'asetrate=44100*1.05,aresample=44100,atempo=0.97,aecho=0.3:0.4:10:0.15',
  ),
  VoiceEffect(
    type: VoiceEffectType.chorusDoubler,
    label: 'Chorus/Doubler',
    emoji: '🎶',
    icon: Icons.content_copy_rounded,
    description: 'Layered, doubled voice',
    ffmpegFilter: 'aecho=0.6:0.7:15|25:0.4|0.3',
  ),
  VoiceEffect(
    type: VoiceEffectType.bassBoost,
    label: 'Bass Boost',
    emoji: '🔊',
    icon: Icons.graphic_eq_rounded,
    description: 'Heavy low-end emphasis',
    ffmpegFilter: 'asetrate=44100*0.9,aresample=44100,atempo=1.11,volume=1.3',
  ),
  VoiceEffect(
    type: VoiceEffectType.glitch,
    label: 'Glitch',
    emoji: '⚡',
    icon: Icons.bolt_rounded,
    description: 'Stuttering, digitally broken',
    ffmpegFilter: 'tremolo=f=15:d=0.7,acrusher=bits=4:mode=lin',
  ),
];

/// Looks up a [VoiceEffect] definition by its enum type.
/// Returns null for [VoiceEffectType.none] (i.e. "no effect applied").
VoiceEffect? voiceEffectFor(VoiceEffectType type) {
  if (type == VoiceEffectType.none) return null;
  return kVoiceEffects.firstWhere((e) => e.type == type);
}
