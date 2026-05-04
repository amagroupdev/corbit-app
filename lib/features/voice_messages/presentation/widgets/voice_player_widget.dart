import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:orbit_app/core/constants/app_colors.dart';

/// Inline audio player for voice messages.
///
/// Plays either a remote URL ([url]) or a local file path ([localPath]).
/// Whichever is non-null wins; [url] takes precedence when both are set.
///
/// Renders a play/pause button, a progress bar, and the elapsed/total
/// time. The internal [AudioPlayer] is released on [dispose].
class VoicePlayerWidget extends StatefulWidget {
  const VoicePlayerWidget({
    super.key,
    this.url,
    this.localPath,
    this.compact = false,
  }) : assert(url != null || localPath != null,
            'Provide either url or localPath');

  /// Remote URL of the audio file.
  final String? url;

  /// Absolute path to a local audio file.
  final String? localPath;

  /// Whether to render a smaller variant suitable for list rows.
  final bool compact;

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _positionSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });

    _durationSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = widget.url;
      final local = widget.localPath;
      if (url != null && url.isNotEmpty) {
        await _player.play(UrlSource(url));
      } else if (local != null && local.isNotEmpty) {
        await _player.play(DeviceFileSource(local));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _duration.inMilliseconds <= 0
        ? 1.0
        : _duration.inMilliseconds.toDouble();
    final value = _position.inMilliseconds
        .clamp(0, _duration.inMilliseconds)
        .toDouble();

    final iconSize = widget.compact ? 22.0 : 28.0;
    final buttonSize = widget.compact ? 36.0 : 44.0;

    return Row(
      children: [
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isLoading ? null : _togglePlay,
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: iconSize - 6,
                        height: iconSize - 6,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: iconSize,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: widget.compact ? 2.0 : 3.0,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: widget.compact ? 6.0 : 7.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceVariant,
                  thumbColor: AppColors.primary,
                ),
                child: Slider(
                  value: value,
                  min: 0,
                  max: maxMs,
                  onChanged: (v) {
                    _player.seek(Duration(milliseconds: v.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(_position),
                      style: TextStyle(
                        fontSize: widget.compact ? 11 : 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      _format(_duration),
                      style: TextStyle(
                        fontSize: widget.compact ? 11 : 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
