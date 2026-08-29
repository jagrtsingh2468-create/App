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
  babyVoice,
  drunkVoice,
  underwater,
  cartoonSqueak,
  oldTimer,
  ghostDemon,
  giantOgre,
  zombie,
  werewolf,
  fairy,
  autotune,
  chorusDoubler,
  bassBoost,
  whisperToShout,
  chiptune8bit,
  studioClean,
  podcastVoice,
  glitch,
  broadcastAnnouncer,
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
  VoiceEffect(
    type: VoiceEffectType.babyVoice,
    label: 'Baby Voice',
    emoji: '👶',
    icon: Icons.child_care_rounded,
    description: 'High, small and playful',
    ffmpegFilter: 'asetrate=44100*1.6,aresample=44100,atempo=0.9',
  ),
  VoiceEffect(
    type: VoiceEffectType.drunkVoice,
    label: 'Drunk Voice',
    emoji: '🥴',
    icon: Icons.sports_bar_rounded,
    description: 'Wobbly pitch and slurred timing',
    ffmpegFilter: 'vibrato=f=3:d=0.6,atempo=0.88,aecho=0.6:0.7:80:0.3',
  ),
  VoiceEffect(
    type: VoiceEffectType.underwater,
    label: 'Underwater',
    emoji: '🫧',
    icon: Icons.water_rounded,
    description: 'Muffled, submerged tone',
    ffmpegFilter: 'lowpass=f=700,vibrato=f=2:d=0.4,aecho=0.5:0.6:40:0.25',
  ),
  VoiceEffect(
    type: VoiceEffectType.cartoonSqueak,
    label: 'Cartoon Squeak',
    emoji: '🐭',
    icon: Icons.theater_comedy_rounded,
    description: 'Extreme high-pitched squeak',
    ffmpegFilter: 'asetrate=44100*1.9,aresample=44100,atempo=0.8',
  ),
  VoiceEffect(
    type: VoiceEffectType.oldTimer,
    label: 'Old Timer',
    emoji: '👴',
    icon: Icons.elderly_rounded,
    description: 'Raspy, band-limited old radio voice',
    ffmpegFilter:
        'asetrate=44100*0.9,aresample=44100,atempo=1.05,highpass=f=300,lowpass=f=3400,afftdn=nf=-20',
  ),
  VoiceEffect(
    type: VoiceEffectType.ghostDemon,
    label: 'Ghost/Demon',
    emoji: '👻',
    icon: Icons.nightlight_round,
    description: 'Deep, haunting and distant',
    ffmpegFilter:
        'asetrate=44100*0.6,aresample=44100,atempo=1.3,aecho=0.8:0.9:300:0.5',
  ),
  VoiceEffect(
    type: VoiceEffectType.giantOgre,
    label: 'Giant/Ogre',
    emoji: '🗿',
    icon: Icons.landscape_rounded,
    description: 'Massive, booming and slow',
    ffmpegFilter: 'asetrate=44100*0.55,aresample=44100,atempo=1.4,aecho=0.7:0.8:60:0.3',
  ),
  VoiceEffect(
    type: VoiceEffectType.zombie,
    label: 'Zombie',
    emoji: '🧟',
    icon: Icons.mood_bad_rounded,
    description: 'Groaning, ragged growl',
    ffmpegFilter: 'asetrate=44100*0.75,aresample=44100,atempo=1.15,afftdn=nf=-15,vibrato=f=2:d=0.3',
  ),
  VoiceEffect(
    type: VoiceEffectType.werewolf,
    label: 'Werewolf',
    emoji: '🐺',
    icon: Icons.pets_rounded,
    description: 'Guttural, aggressive growl',
    ffmpegFilter: 'asetrate=44100*0.65,aresample=44100,atempo=1.25,vibrato=f=5:d=0.5,aecho=0.6:0.7:50:0.3',
  ),
  VoiceEffect(
    type: VoiceEffectType.fairy,
    label: 'Fairy',
    emoji: '🧚',
    icon: Icons.auto_awesome_rounded,
    description: 'Light, airy and shimmering',
    ffmpegFilter: 'asetrate=44100*1.7,aresample=44100,atempo=0.85,chorus=0.5:0.8:40:0.3:0.2:1.5',
  ),
  VoiceEffect(
    type: VoiceEffectType.autotune,
    label: 'Autotune-ish',
    emoji: '🎤',
    icon: Icons.tune_rounded,
    description: 'Pitch-snap, robotic-singer feel',
    ffmpegFilter: 'vibrato=f=6:d=0.9,atempo=1.0',
  ),
  VoiceEffect(
    type: VoiceEffectType.chorusDoubler,
    label: 'Chorus/Doubler',
    emoji: '🎶',
    icon: Icons.content_copy_rounded,
    description: 'Layered, doubled voice',
    ffmpegFilter: 'chorus=0.7:0.9:55:0.4:0.25:2',
  ),
  VoiceEffect(
    type: VoiceEffectType.bassBoost,
    label: 'Bass Boost',
    emoji: '🔊',
    icon: Icons.graphic_eq_rounded,
    description: 'Heavy low-end emphasis',
    ffmpegFilter: 'bass=g=12:f=110:w=0.6',
  ),
  VoiceEffect(
    type: VoiceEffectType.whisperToShout,
    label: 'Whisper-to-Shout Dynamic',
    emoji: '📢',
    icon: Icons.surround_sound_rounded,
    description: 'Compressed, punchy dynamic range',
    ffmpegFilter: 'acompressor=threshold=-25dB:ratio=4:attack=5:release=50,volume=1.5',
  ),
  VoiceEffect(
    type: VoiceEffectType.chiptune8bit,
    label: '8-bit/Chiptune',
    emoji: '🎮',
    icon: Icons.sports_esports_rounded,
    description: 'Crushed, retro game-console tone',
    ffmpegFilter: 'acrusher=bits=6:mode=log:aa=0.5',
  ),
  VoiceEffect(
    type: VoiceEffectType.studioClean,
    label: 'Studio Clean',
    emoji: '🎧',
    icon: Icons.cleaning_services_rounded,
    description: 'Noise-gated and lightly compressed',
    ffmpegFilter: 'afftdn=nf=-25,acompressor=threshold=-18dB:ratio=3:attack=10:release=80',
  ),
  VoiceEffect(
    type: VoiceEffectType.podcastVoice,
    label: 'Podcast Voice',
    emoji: '🎙️',
    icon: Icons.podcasts_rounded,
    description: 'Warm EQ with gentle compression',
    ffmpegFilter:
        'equalizer=f=200:width_type=o:width=1:g=3,equalizer=f=3000:width_type=o:width=1:g=2,acompressor=threshold=-20dB:ratio=2.5',
  ),
  VoiceEffect(
    type: VoiceEffectType.glitch,
    label: 'Glitch',
    emoji: '⚡',
    icon: Icons.bolt_rounded,
    description: 'Stuttering, digitally broken',
    ffmpegFilter: 'tremolo=f=15:d=0.7,acrusher=bits=4:mode=lin',
  ),
  VoiceEffect(
    type: VoiceEffectType.broadcastAnnouncer,
    label: 'Broadcast Announcer',
    emoji: '📻',
    icon: Icons.campaign_rounded,
    description: 'Deep, compressed radio-announcer tone',
    ffmpegFilter:
        'asetrate=44100*0.85,aresample=44100,atempo=1.15,acompressor=threshold=-15dB:ratio=4,equalizer=f=150:width_type=o:width=1:g=4',
  ),
];

/// Looks up a [VoiceEffect] definition by its enum type.
/// Returns null for [VoiceEffectType.none] (i.e. "no effect applied").
VoiceEffect? voiceEffectFor(VoiceEffectType type) {
  if (type == VoiceEffectType.none) return null;
  return kVoiceEffects.firstWhere((e) => e.type == type);
}
