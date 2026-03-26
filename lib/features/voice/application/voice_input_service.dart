// lib/features/voice/application/voice_input_service.dart
//
// Sprint 3.9 — Group A (A1, A4, A5)
// Central orchestrator for the voice-to-intent pipeline.
//
// Pipeline:
//   startListening()
//     → AiChannel.startRecording()          (mic capture)
//     → AiChannel.stopRecording()           (returns PCM bytes)
//     → AiChannel.transcribeAudio()         (Whisper-tiny INT8, on-device)
//     → ParseVoiceInputUseCase.execute()    (NLU — heuristic pipeline)
//     → emit VoiceParsedIntent or VoiceClarifying
//
// SC-01: Zero cloud AI — all inference on-device via AiChannel.
// FR-P02: No audio bytes or transcripts leave the device.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tazakar/features/nlu/application/clarification_dialogue_use_case.dart';
import 'package:tazakar/features/nlu/application/parse_voice_input_use_case.dart';
import 'package:tazakar/features/nlu/domain/entities/parsed_intent.dart';
import 'package:tazakar/features/voice/domain/errors/voice_error.dart';
import 'package:tazakar/features/voice/domain/states/voice_input_state.dart';
import 'package:tazakar/infrastructure/platform/ai_channel.dart';

class VoiceInputService {
  VoiceInputService({
    required ParseVoiceInputUseCase parseUseCase,
    required ClarificationDialogueUseCase clarificationUseCase,
    AiChannel? aiChannel,
  })  : _parseUseCase = parseUseCase,
        _clarificationUseCase = clarificationUseCase,
        _aiChannel = aiChannel ?? AiChannel.instance;

  final ParseVoiceInputUseCase _parseUseCase;
  final ClarificationDialogueUseCase _clarificationUseCase;
  final AiChannel _aiChannel;

  final _controller = StreamController<VoiceInputState>.broadcast();

  /// Stream of pipeline states. UI layer listens to this.
  Stream<VoiceInputState> get stream => _controller.stream;

  /// Current state — starts idle.
  VoiceInputState _state = const VoiceIdle();
  VoiceInputState get state => _state;

  bool _isListening = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Starts the full voice-to-intent pipeline.
  ///
  /// Emits states in order:
  ///   VoiceListening → VoiceTranscribing → VoiceParsedIntent | VoiceClarifying
  ///
  /// Emits VoiceErrorState on any failure. Always returns to a callable
  /// state after an error (does not lock up).
  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;

    try {
      // Step 1 — Start recording
      _emit(const VoiceListening());
      final started = await _aiChannel.startRecording();
      if (!started) {
        _emit(const VoiceErrorState(VoiceError.micDenied));
        return;
      }

      // Step 2 — Stop recording and get PCM bytes
      _emit(const VoiceTranscribing());
      final audioBytes = await _aiChannel.stopRecording();
      if (audioBytes == null || audioBytes.isEmpty) {
        _emit(const VoiceErrorState(VoiceError.whisperTimeout));
        return;
      }

      // Step 3 — Transcribe on-device (Whisper-tiny INT8)
      final transcript = await _aiChannel.transcribeAudio(audioBytes);
      if (transcript == null || transcript.trim().isEmpty) {
        _emit(const VoiceErrorState(VoiceError.whisperTimeout));
        return;
      }

      debugPrint('[VoiceInputService] Transcript: $transcript');

      // Step 4 — NLU parse (heuristic pipeline, DEC-33)
      final intent = await _parseUseCase.execute(transcript);

      // Step 5 — Route: actionable vs needs clarification
      _routeIntent(intent);
    } catch (e) {
      debugPrint('[VoiceInputService] Unexpected error: $e');
      _emit(const VoiceErrorState(VoiceError.parseFailed));
    } finally {
      _isListening = false;
    }
  }

  /// Stops an in-progress recording early (e.g. user taps mic again).
  /// No-op if not currently listening.
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _aiChannel.stopRecording();
    _isListening = false;
    _emit(const VoiceIdle());
  }

  /// Applies a clarification answer and re-routes the updated intent.
  ///
  /// Called after the user responds to a ClarificationCard prompt.
  void applyClarification(
    ParsedIntent original,
    ExtractedEntities updatedEntities,
  ) {
    final updated =
        _clarificationUseCase.applyAnswer(original, updatedEntities);
    _routeIntent(updated);
  }

  /// Resets the service back to idle without stopping any active recording.
  void reset() {
    _isListening = false;
    _emit(const VoiceIdle());
  }

  /// Releases the stream controller. Call from the Riverpod provider's
  /// onDispose or from the ViewModel dispose.
  void dispose() {
    _controller.close();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _emit(VoiceInputState state) {
    _state = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  /// Routes a [ParsedIntent] to either VoiceParsedIntent or VoiceClarifying.
  ///
  /// Clarification is triggered when:
  ///   - intent.clarificationNeeded == true, OR
  ///   - confidence < 0.6 (below auto-create threshold), OR
  ///   - title or scheduledAt is missing
  void _routeIntent(ParsedIntent intent) {
    final question = _clarificationUseCase.nextQuestion(intent);

    if (question != null) {
      _emit(VoiceClarifying(intent: intent, question: question));
    } else {
      _emit(VoiceParsedIntent(intent));
    }
  }
}
