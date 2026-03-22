import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter-side platform channel for on-device AI inference.
///
/// Communicates with native Swift (iOS) and Kotlin (Android) implementations
/// via the [MethodChannel] at [channelName].
///
/// Hard constraints honoured:
///   SC-01  Zero cloud AI — all inference runs on-device only
///   FR-P02 Zero user data transmitted to any server
class AiChannel {
  AiChannel._();
  static final AiChannel instance = AiChannel._();

  static const String channelName = 'com.tazakar.app/ai_channel';

  final MethodChannel _channel = const MethodChannel(channelName);

  // ─────────────────────────────────────────────
  // MODEL MANAGEMENT
  // ─────────────────────────────────────────────

  /// Loads the Whisper-tiny INT8 model into memory on the native side.
  /// Returns [true] on success, [false] on failure.
  /// Must be called before [transcribeAudio].
  Future<bool> loadModel() async {
    try {
      final result = await _channel.invokeMethod<bool>('loadModel');
      debugPrint('[AiChannel] loadModel → $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AiChannel] loadModel error: ${e.message}');
      return false;
    }
  }

  /// Returns [true] if the Whisper model is loaded and ready for inference.
  Future<bool> isModelLoaded() async {
    try {
      final result = await _channel.invokeMethod<bool>('isModelLoaded');
      debugPrint('[AiChannel] isModelLoaded → $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AiChannel] isModelLoaded error: ${e.message}');
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // TRANSCRIPTION
  // ─────────────────────────────────────────────

  /// Sends raw PCM audio bytes to the native Whisper-tiny INT8 model
  /// and returns the transcribed Arabic text.
  ///
  /// [audioBytes] — raw PCM 16-bit mono 16kHz audio data.
  /// Returns [null] if transcription fails or model is not loaded.
  Future<String?> transcribeAudio(Uint8List audioBytes) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'transcribeAudio',
        {'audioBytes': audioBytes},
      );
      debugPrint(
        '[AiChannel] transcribeAudio → ${result?.length ?? 0} chars',
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[AiChannel] transcribeAudio error: ${e.message}');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // AUDIO RECORDING
  // ─────────────────────────────────────────────

  /// Starts recording audio on the native side.
  /// Returns [true] if recording started successfully.
  Future<bool> startRecording() async {
    try {
      final result = await _channel.invokeMethod<bool>('startRecording');
      debugPrint('[AiChannel] startRecording → $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AiChannel] startRecording error: ${e.message}');
      return false;
    }
  }

  /// Stops recording and returns the captured PCM audio bytes.
  /// Returns [null] if recording failed or was not started.
  Future<Uint8List?> stopRecording() async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('stopRecording');
      debugPrint(
        '[AiChannel] stopRecording → ${result?.length ?? 0} bytes',
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('[AiChannel] stopRecording error: ${e.message}');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // CONVENIENCE
  // ─────────────────────────────────────────────

  /// Records audio and immediately transcribes it in one call.
  /// Combines [startRecording], [stopRecording], and [transcribeAudio].
  /// Returns [null] if any step fails.
  Future<String?> recordAndTranscribe() async {
    final started = await startRecording();
    if (!started) return null;

    // Recording duration is controlled by the native side (VAD-based).
    final audioBytes = await stopRecording();
    if (audioBytes == null || audioBytes.isEmpty) return null;

    return transcribeAudio(audioBytes);
  }
}
