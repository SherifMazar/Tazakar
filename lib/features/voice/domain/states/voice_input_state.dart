// lib/features/voice/domain/states/voice_input_state.dart
//
// Sprint 3.9 — Group A (A2)
// Sealed class representing every state VoiceInputService can emit.
// Consumed by the UI layer (HomeScreen) via a StreamProvider or watch.

import 'package:tazakar/features/nlu/domain/entities/parsed_intent.dart';
import 'package:tazakar/features/nlu/application/clarification_dialogue_use_case.dart';
import 'package:tazakar/features/voice/domain/errors/voice_error.dart';

sealed class VoiceInputState {
  const VoiceInputState();
}

/// Initial state — mic is idle, nothing in progress.
final class VoiceIdle extends VoiceInputState {
  const VoiceIdle();
}

/// AiChannel.startRecording() succeeded — actively capturing audio.
final class VoiceListening extends VoiceInputState {
  const VoiceListening();
}

/// Audio captured — Whisper transcription in progress on-device.
final class VoiceTranscribing extends VoiceInputState {
  const VoiceTranscribing();
}

/// NLU parsing complete and intent is actionable (confidence >= 0.7,
/// title present, scheduledAt present). Ready to create reminder.
final class VoiceParsedIntent extends VoiceInputState {
  const VoiceParsedIntent(this.intent);
  final ParsedIntent intent;
}

/// NLU parsing complete but one or more fields are missing or ambiguous.
/// UI should show ClarificationCard with [question].
final class VoiceClarifying extends VoiceInputState {
  const VoiceClarifying({required this.intent, required this.question});
  final ParsedIntent intent;
  final ClarificationQuestion question;
}

/// An error occurred at any stage of the pipeline. See [VoiceError] for
/// UI handling guidance.
final class VoiceErrorState extends VoiceInputState {
  const VoiceErrorState(this.error);
  final VoiceError error;
}
