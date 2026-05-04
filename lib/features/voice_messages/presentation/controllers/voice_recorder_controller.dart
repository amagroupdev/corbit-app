import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Lifecycle of the audio recorder.
enum VoiceRecorderStatus {
  /// Recorder is idle (initial state, also after [stop]).
  idle,

  /// Microphone permission was requested but denied.
  permissionDenied,

  /// Recorder is currently capturing audio.
  recording,

  /// Recording is paused but resumable.
  paused,
}

/// State for the voice recorder.
class VoiceRecorderState {
  const VoiceRecorderState({
    this.status = VoiceRecorderStatus.idle,
    this.elapsed = Duration.zero,
    this.recordingPath,
    this.error,
  });

  final VoiceRecorderStatus status;
  final Duration elapsed;
  final String? recordingPath;
  final String? error;

  bool get isRecording => status == VoiceRecorderStatus.recording;
  bool get isPaused => status == VoiceRecorderStatus.paused;
  bool get isActive => isRecording || isPaused;
  bool get hasRecording =>
      recordingPath != null && status == VoiceRecorderStatus.idle;

  VoiceRecorderState copyWith({
    VoiceRecorderStatus? status,
    Duration? elapsed,
    String? recordingPath,
    bool clearRecordingPath = false,
    String? error,
    bool clearError = false,
  }) {
    return VoiceRecorderState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      recordingPath: clearRecordingPath
          ? null
          : (recordingPath ?? this.recordingPath),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controls the on-device recorder.
///
/// Files are written to the OS temporary directory as `voice_<ts>.m4a`
/// and stay there until [discard] is invoked or the app reuses the
/// directory.
class VoiceRecorderController extends StateNotifier<VoiceRecorderState> {
  VoiceRecorderController({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder(),
        super(const VoiceRecorderState());

  final AudioRecorder _recorder;
  Timer? _ticker;
  DateTime? _segmentStart;
  Duration _accumulated = Duration.zero;

  /// Starts a new recording. Resets any previously captured file.
  Future<void> start() async {
    if (state.isActive) return;

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      state = state.copyWith(error: 'recorder_unsupported_platform');
      return;
    }

    final granted = await _ensurePermission();
    if (!granted) {
      state = const VoiceRecorderState(
        status: VoiceRecorderStatus.permissionDenied,
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/voice_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _accumulated = Duration.zero;
      _segmentStart = DateTime.now();
      _startTicker();

      state = VoiceRecorderState(
        status: VoiceRecorderStatus.recording,
        elapsed: Duration.zero,
        recordingPath: path,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Pauses an active recording.
  Future<void> pause() async {
    if (!state.isRecording) return;
    try {
      await _recorder.pause();
      _accumulated = _currentElapsed();
      _segmentStart = null;
      _stopTicker();
      state = state.copyWith(
        status: VoiceRecorderStatus.paused,
        elapsed: _accumulated,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Resumes a paused recording.
  Future<void> resume() async {
    if (!state.isPaused) return;
    try {
      await _recorder.resume();
      _segmentStart = DateTime.now();
      _startTicker();
      state = state.copyWith(status: VoiceRecorderStatus.recording);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Stops the recorder and returns the path to the captured file
  /// (or `null` if no file was produced).
  Future<String?> stop() async {
    if (!state.isActive) return state.recordingPath;
    try {
      final path = await _recorder.stop();
      _accumulated = _currentElapsed();
      _stopTicker();
      _segmentStart = null;

      state = state.copyWith(
        status: VoiceRecorderStatus.idle,
        elapsed: _accumulated,
        recordingPath: path ?? state.recordingPath,
      );
      return path ?? state.recordingPath;
    } catch (e) {
      state = state.copyWith(
        status: VoiceRecorderStatus.idle,
        error: e.toString(),
      );
      return state.recordingPath;
    }
  }

  /// Cancels the active recording and clears the captured file path.
  Future<void> discard() async {
    if (state.isActive) {
      try {
        await _recorder.cancel();
      } catch (_) {
        // ignore — we're throwing the file away anyway
      }
    }
    _accumulated = Duration.zero;
    _segmentStart = null;
    _stopTicker();
    state = const VoiceRecorderState();
  }

  /// Resets state to idle without deleting the captured file. Useful
  /// after the file has been uploaded successfully.
  void clear() {
    _accumulated = Duration.zero;
    _segmentStart = null;
    _stopTicker();
    state = const VoiceRecorderState();
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      state = state.copyWith(elapsed: _currentElapsed());
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Duration _currentElapsed() {
    final segment = _segmentStart;
    if (segment == null) return _accumulated;
    return _accumulated + DateTime.now().difference(segment);
  }

  @override
  void dispose() {
    _stopTicker();
    _recorder.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the voice recorder controller. Auto-disposed so the
/// underlying [AudioRecorder] is released when the screen pops.
final voiceRecorderControllerProvider =
    StateNotifierProvider.autoDispose<VoiceRecorderController, VoiceRecorderState>(
  (ref) => VoiceRecorderController(),
);
