# Voice Changer — Study Chaos

A Flutter voice-changer app: record or import audio, apply one of nine
on-device effects, preview, save, and share — all offline, no server.

---

## ⚠️ One important package note

`ffmpeg_kit_flutter` (the package almost every Flutter voice-changer
tutorial uses) was **retired by its maintainer in 2025** and pulled from
pub.dev. This project uses the actively-maintained community continuation,
**`ffmpeg_kit_flutter_new`**, which has the same API. Before building,
run `flutter pub get` and check pub.dev for the latest version number, since
FFmpeg-Kit forks occasionally rename or split (e.g. into "min/audio/full"
build flavors) — swap the dependency line in `pubspec.yaml` if needed.

---

## Project folder structure

```
voice_changer_app/
├── android/                          # Native Android project (Gradle, manifest, signing)
│   ├── app/
│   │   ├── build.gradle              # App-level build config + release signing
│   │   ├── proguard-rules.pro        # Keep-rules for release code shrinking
│   │   └── src/main/
│   │       ├── AndroidManifest.xml   # Permissions + FileProvider + app entry
│   │       ├── kotlin/.../MainActivity.kt
│   │       └── res/                  # Themes, launch background, FileProvider paths
│   ├── build.gradle                  # Project-level Gradle config
│   ├── settings.gradle
│   ├── gradle.properties
│   └── key.properties.template       # Copy -> key.properties, fill in your keystore
│
├── lib/
│   ├── main.dart                     # App entry point + dependency injection
│   │
│   ├── core/                         # Cross-cutting, framework-agnostic helpers
│   │   ├── constants/
│   │   │   ├── app_colors.dart       # Brand color palette
│   │   │   ├── app_strings.dart      # All user-facing copy
│   │   │   └── voice_effects.dart    # The 9 effects + their FFmpeg filter graphs
│   │   ├── theme/app_theme.dart      # Material 3 light/dark ThemeData
│   │   ├── error/failures.dart       # Typed, UI-safe error classes
│   │   └── utils/
│   │       ├── permission_util.dart  # Mic/storage runtime permission requests
│   │       └── file_utils.dart       # Path building, size/duration formatting
│   │
│   ├── domain/                       # Pure business logic — no Flutter, no plugins
│   │   ├── entities/recording.dart   # Core Recording entity
│   │   ├── repositories/audio_repository.dart  # Abstract contract
│   │   └── usecases/                 # One class per user action
│   │       ├── record_audio.dart
│   │       ├── apply_effect.dart
│   │       ├── save_recording.dart
│   │       ├── delete_recording.dart
│   │       └── share_recording.dart
│   │
│   ├── data/                         # Concrete implementations of the domain contracts
│   │   ├── models/recording_model.dart          # Recording + JSON (de)serialization
│   │   ├── services/
│   │   │   ├── audio_recorder_service.dart      # Wraps `record` plugin
│   │   │   ├── audio_effects_service.dart       # Wraps FFmpeg-Kit
│   │   │   ├── audio_player_service.dart        # Wraps `audioplayers`
│   │   │   └── storage_service.dart             # File picker, library persistence, sharing
│   │   └── repositories/audio_repository_impl.dart  # Composes all 4 services
│   │
│   └── presentation/                 # Everything Flutter-widget-related
│       ├── providers/                # State management (Provider/ChangeNotifier)
│       │   ├── theme_provider.dart
│       │   ├── recorder_provider.dart
│       │   └── library_provider.dart
│       ├── screens/
│       │   ├── home_screen.dart
│       │   ├── record_screen.dart
│       │   ├── effects_screen.dart
│       │   └── library_screen.dart
│       └── widgets/
│           ├── animated_record_button.dart
│           ├── effect_card.dart
│           ├── recording_tile.dart
│           └── waveform_widget.dart
│
├── assets/audio/                     # (empty — reserved for bundled sound assets)
├── pubspec.yaml
├── analysis_options.yaml
└── .gitignore
```

### Why this structure (Clean Architecture)

- **`domain/`** never imports Flutter or any plugin. It defines *what* the
  app does (`AudioRepository` interface, use cases) without caring *how*.
- **`data/`** implements the domain contracts using real plugins
  (`record`, `ffmpeg_kit_flutter_new`, `audioplayers`, `file_picker`,
  `share_plus`, `shared_preferences`). Swap any plugin later by rewriting
  one service file — nothing else changes.
- **`presentation/`** only talks to the domain layer through use cases /
  the repository interface, injected via `Provider` in `main.dart`.

This separation is what makes the codebase testable and maintainable as it
grows — e.g. you could unit-test `RecorderProvider` with a fake
`AudioRepository` and never touch a real microphone or FFmpeg binary.

---

## How each of the 9 effects works

All effects are implemented as **FFmpeg audio-filter graphs** (see
`lib/core/constants/voice_effects.dart`), run locally via
`ffmpeg_kit_flutter_new` — no audio ever leaves the device:

| Effect | Technique |
|---|---|
| Chipmunk | `asetrate` speeds up + raises pitch, `atempo` corrects overall speed slightly |
| Deep Voice | `asetrate` slows down + lowers pitch, `atempo` compensates |
| Robot | Noise gate + `vibrato` + short `aecho` for a metallic buzz |
| Echo | `aecho` with a single long, fading repeat |
| Reverb | Multiple short-delay `aecho` taps layered to fake a room |
| Alien | Pitch shift + `vibrato` + `chorus` for a wobbly, doubled tone |
| Helium | Aggressive `asetrate` pitch-up |
| Slow Motion | `atempo` < 1, pitch unchanged |
| Fast Voice | `atempo` > 1, pitch unchanged |

---

## 1. Required Flutter packages

```yaml
provider: ^6.1.2                     # State management
record: ^5.1.2                       # Microphone recording
audioplayers: ^6.0.0                 # Playback
ffmpeg_kit_flutter_new: ^1.6.0       # Voice-effect processing (community fork)
permission_handler: ^11.3.1          # Runtime permissions
path_provider: ^2.1.3                # App storage directories
file_picker: ^8.0.6                  # Import audio files
share_plus: ^9.0.0                   # Share to other apps
path: ^1.9.0                         # Path utilities
shared_preferences: ^2.2.3           # Local recording-library index + theme setting
uuid: ^4.4.0                         # Unique IDs
google_fonts: ^6.2.1                 # Typography
lottie: ^3.1.2                       # (optional) micro-animations
intl: ^0.19.0                        # Date formatting
cupertino_icons: ^1.0.8

# dev
flutter_lints: ^4.0.0
```

Install everything with:

```bash
flutter pub get
```

Check `flutter pub outdated` before release and bump to the latest stable
patch versions — pin exact versions in a real production release for
reproducible builds.

---

## 2. How to build the APK / App Bundle

### a. One-time setup

```bash
flutter --version        # confirm you're on the latest stable channel
flutter doctor           # resolve any missing Android toolchain items
flutter pub get
```

### b. Generate a release keystore (one time only, keep it forever)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (copy from
`android/key.properties.template`) and fill in the real values:

```properties
storePassword=<your password>
keyPassword=<your password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

**Never commit this file or the `.jks` to version control** — `.gitignore`
already excludes both.

### c. Build a release App Bundle (required for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### d. (Optional) Build a signed APK for direct testing

```bash
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`

### e. Verify the signing

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

---

## 3. How to publish on Google Play Store

1. **Create a Play Console account** (one-time $25 fee) at
   https://play.google.com/console.
2. **Create a new app** → fill in title, default language, app/game type,
   free/paid.
3. **App content questionnaire**: complete privacy policy URL (required —
   this app records audio, so you must clearly disclose that in your
   policy and that recordings stay on-device unless the user shares them),
   target audience, ads declaration, data safety form (declare "Audio" /
   "Microphone" data collected but not shared with third parties, stored
   locally).
4. **Store listing**: add screenshots (at least 2, phone + optionally
   tablet), a 512×512 hi-res icon, a feature graphic (1024×500), short
   description (≤80 chars), full description.
5. **Production release**: go to *Release → Production → Create new
   release*, upload the `.aab` from step 2c, add release notes.
6. **Set countries/pricing**, confirm content rating questionnaire
   (complete the IARC rating survey — a voice-changer app is typically
   rated for all ages, but answer honestly).
7. **Review and roll out**. Google typically reviews within a few hours to
   a few days for a new app.
8. After approval, the app is live. For future updates: bump
   `version:` in `pubspec.yaml` (e.g. `1.0.1+2` — the number after `+` is
   the required-to-increase `versionCode`), rebuild the `.aab`, and upload
   a new production release.

### Play Store checklist specific to this app
- Microphone permission usage is disclosed in your privacy policy and in
  the Data Safety section (required — Google actively reviews apps
  requesting `RECORD_AUDIO`).
- No third-party analytics/ads SDKs are bundled in this starter project;
  if you add any later, update the Data Safety form accordingly.
- `minSdkVersion 26` (Android 8.0) matches the stated compatibility
  requirement.
- ProGuard/R8 minification is already enabled in `android/app/build.gradle`
  release build type, keeping the release build small.

---

## Performance & battery notes

- FFmpeg processing runs once per effect selection (not continuously),
  and only while the app is foregrounded — no background CPU usage.
- Recording uses AAC-LC at a modest 128kbps/44.1kHz mono, keeping both
  file sizes and encoding CPU load low.
- The waveform UI is a lightweight procedural visualization rather than
  full PCM decoding, avoiding unnecessary decode overhead just to draw a
  preview.

---

## Running locally

```bash
flutter pub get
flutter run
```

Grant microphone permission when prompted on first recording attempt.
