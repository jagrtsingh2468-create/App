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
  final String description;
  final String ffmpegFilter;

  const VoiceEffect({
    required this.type,
    required this.label,
    required this.emoji,
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
    description: 'High-pitched, fast and squeaky',
    ffmpegFilter: 'asetrate=44100*1.5,aresample=44100,atempo=0.9',
  ),
  VoiceEffect(
    type: VoiceEffectType.deepVoice,
    label: 'Deep Voice',
    emoji: '🗿',
    description: 'Low, slow and powerful',
    ffmpegFilter: 'asetrate=44100*0.7,aresample=44100,atempo=1.1',
  ),
  VoiceEffect(
    type: VoiceEffectType.robot,
    label: 'Robot',
    emoji: '🤖',
    description: 'Metallic, mechanical tone',
    ffmpegFilter:
        'afftdn=nf=-25,vibrato=f=8:d=0.6,aecho=0.8:0.7:20:0.4,atempo=1.0',
  ),
  VoiceEffect(
    type: VoiceEffectType.echo,
    label: 'Echo',
    emoji: '📢',
    description: 'Repeating fading echo',
    ffmpegFilter: 'aecho=0.8:0.85:500:0.5',
  ),
  VoiceEffect(
    type: VoiceEffectType.reverb,
    label: 'Reverb',
    emoji: '🏛️',
    description: 'Big hall / cathedral space',
    ffmpegFilter: 'aecho=0.8:0.9:40|80|120:0.35|0.25|0.15',
  ),
  VoiceEffect(
    type: VoiceEffectType.alien,
    label: 'Alien',
    emoji: '👽',
    description: 'Wobbly, otherworldly voice',
    ffmpegFilter:
        'asetrate=44100*1.2,aresample=44100,vibrato=f=6:d=0.8,chorus=0.6:0.9:55:0.4:0.25:2',
  ),
  VoiceEffect(
    type: VoiceEffectType.helium,
    label: 'Helium',
    emoji: '🎈',
    description: 'Very high, cartoonish pitch',
    ffmpegFilter: 'asetrate=44100*1.8,aresample=44100,atempo=0.85',
  ),
  VoiceEffect(
    type: VoiceEffectType.slowMotion,
    label: 'Slow Motion',
    emoji: '🐢',
    description: 'Slowed down, same pitch',
    ffmpegFilter: 'atempo=0.7',
  ),
  VoiceEffect(
    type: VoiceEffectType.fastVoice,
    label: 'Fast Voice',
    emoji: '🐇',
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
