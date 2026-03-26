// lib/features/voice/domain/errors/voice_error.dart
//
// Sprint 3.9 — Group A (A3)
// All error states that can be emitted by VoiceInputService.

/// Enumerates every failure mode in the voice-to-reminder pipeline.
///
/// UI handling:
///   micDenied           → redirect to SCR-03 (permissions screen)
///   whisperTimeout      → inline snackbar + retry option
///   parseFailed         → inline snackbar + text fallback CTA
///   saveFailed          → inline snackbar + retry option
///   notificationFailed  → reminder saved but notification not scheduled; warn only
enum VoiceError {
  /// Microphone permission denied by the user or OS.
  micDenied,

  /// AiChannel.startRecording() returned false, stopRecording() returned null,
  /// or transcribeAudio() returned null. Covers timeout scenarios.
  whisperTimeout,

  /// ParseVoiceInputUseCase returned a ParsedIntent with confidence == 0.0
  /// and an empty transcript (blank audio / unrecognised speech).
  parseFailed,

  /// CreateReminderUseCase threw an unexpected exception (DB write failure).
  /// Does NOT cover freeTierCapReached — that is a separate ViewModel state.
  saveFailed,

  /// NotificationService.scheduleReminder() threw an exception after the
  /// reminder was already saved. Reminder exists in DB; notification missing.
  notificationFailed,
}
