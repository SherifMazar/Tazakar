// lib/features/voice/infrastructure/voice_providers.dart
//
// Sprint 3.9 — Group A (A6)
// Riverpod providers for the voice feature.
//
// VoiceInputService is created as an auto-disposed StreamProvider so the
// stream is torn down when no widget is listening. The service itself is
// exposed separately so the ViewModel can call startListening() imperatively.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/features/nlu/infrastructure/nlu_providers.dart';
import 'package:tazakar/features/voice/application/voice_input_service.dart';
import 'package:tazakar/features/voice/domain/states/voice_input_state.dart';

// ── Service provider ──────────────────────────────────────────────────────────

/// Provides a single [VoiceInputService] instance for the lifetime of the
/// widget tree that watches it. Disposed automatically when no longer watched.
final voiceInputServiceProvider = Provider.autoDispose<VoiceInputService>((ref) {
  final service = VoiceInputService(
    parseUseCase: ref.watch(parseVoiceInputUseCaseProvider),
    clarificationUseCase: ref.watch(clarificationDialogueUseCaseProvider),
  );

  ref.onDispose(service.dispose);

  return service;
});

// ── Stream provider ───────────────────────────────────────────────────────────

/// Exposes the [VoiceInputService.stream] as a Riverpod [StreamProvider].
///
/// UI widgets watch this to reactively rebuild on state changes:
///
///   final state = ref.watch(voiceInputStateProvider);
///   state.when(
///     data: (s) => ...,
///     loading: () => ...,
///     error: (e, _) => ...,
///   );
final voiceInputStateProvider =
    StreamProvider.autoDispose<VoiceInputState>((ref) {
  final service = ref.watch(voiceInputServiceProvider);
  return service.stream;
});
