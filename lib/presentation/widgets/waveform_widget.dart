import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// Renders the real waveform for the given recording file.
///
/// Assumption (adjust if your current widget's constructor differs):
/// this widget takes the recording's file path and builds/owns its own
/// PlayerController internally. If your EditorPlaceholderScreen already
/// owns a PlayerController (e.g. for play/pause preview), let me know and
/// I'll change this to accept an external controller instead of creating
/// one here, so we don't end up with two controllers on the same file.
class WaveformWidget extends StatefulWidget {
  final String filePath;
  final double height;
  final Color waveColor;
  final Color liveWaveColor;

  const WaveformWidget({
    super.key,
    required this.filePath,
    this.height = 100,
    this.waveColor = Colors.grey,
    this.liveWaveColor = Colors.blueAccent,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  late final PlayerController _playerController;
  bool _isLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _preparePlayer();
  }

  Future<void> _preparePlayer() async {
    try {
      await _playerController.preparePlayer(
        path: widget.filePath,
        shouldExtractWaveform: true,
        noOfSamples: 100,
      );
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Waveform unavailable',
            style: TextStyle(color: Colors.red.shade300),
          ),
        ),
      );
    }

    if (!_isLoaded) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return AudioFileWaveforms(
      size: Size(MediaQuery.of(context).size.width - 32, widget.height),
      playerController: _playerController,
      enableSeekGesture: true,
      waveformType: WaveformType.long,
      playerWaveStyle: PlayerWaveStyle(
        fixedWaveColor: widget.waveColor,
        liveWaveColor: widget.liveWaveColor,
        spacing: 6,
        showSeekLine: true,
      ),
    );
  }
}
