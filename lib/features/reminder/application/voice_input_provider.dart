import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../infrastructure/platform/ai_channel.dart';
import '../../../features/nlu/application/parse_voice_input_use_case.dart';
import '../../../features/nlu/application/clarification_dialogue_use_case.dart';
import '../../../features/nlu/domain/entities/parsed_intent.dart';
import '../../../features/nlu/infrastructure/nlu_providers.dart';

enum VoiceInputStatus { idle, recording, processing, clarifying, actionable, error }

class VoiceInputState {
  final VoiceInputStatus status;
  final String? transcript;
  final ParsedIntent? parsedIntent;
  final ClarificationQuestion? currentQuestion;
  final String? errorMessage;

  const VoiceInputState({
    this.status = VoiceInputStatus.idle,
    this.transcript,
    this.parsedIntent,
    this.currentQuestion,
    this.errorMessage,
  });

  VoiceInputState copyWith({
    VoiceInputStatus? status,
    String? transcript,
    ParsedIntent? parsedIntent,
    ClarificationQuestion? currentQuestion,
    String? errorMessage,
  }) {
    return VoiceInputState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      parsedIntent: parsedIntent ?? this.parsedIntent,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final ParseVoiceInputUseCase _parseUseCase;
  final ClarificationDialogueUseCase _clarificationUseCase;
  final AiChannel _aiChannel;

  VoiceInputNotifier(this._parseUseCase, this._clarificationUseCase, this._aiChannel)
      : super(const VoiceInputState());

  Future<void> startRecording() async {
    state = state.copyWith(status: VoiceInputStatus.recording, errorMessage: null);
    final started = await _aiChannel.startRecording();
    if (!started) {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        errorMessage: 'تعذّر الوصول إلى الميكروفون.\nMicrophone unavailable.',
      );
    }
  }

  Future<void> stopAndTranscribe() async {
    state = state.copyWith(status: VoiceInputStatus.processing);
    try {
      final audioBytes = await _aiChannel.stopRecording();
      if (audioBytes == null || audioBytes.isEmpty) {
        state = state.copyWith(
          status: VoiceInputStatus.error,
          errorMessage: 'لم يتم التقاط صوت. حاول مرة أخرى.\nNo audio captured. Please try again.',
        );
        return;
      }
      final transcript = await _aiChannel.transcribeAudio(audioBytes);
      if (transcript == null || transcript.isEmpty) {
        state = state.copyWith(
          status: VoiceInputStatus.error,
          errorMessage: 'لم يتم التعرف على الكلام. حاول مرة أخرى.\nSpeech not recognized. Please try again.',
        );
        return;
      }
      state = state.copyWith(transcript: transcript);
      await _runNlu(transcript);
    } catch (_) {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        errorMessage: 'انتهت مهلة المعالجة. حاول مرة أخرى.\nProcessing timed out. Please try again.',
      );
    }
  }

  Future<void> onTextInput(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(status: VoiceInputStatus.processing, transcript: text);
    await _runNlu(text);
  }

  Future<void> _runNlu(String transcript) async {
    try {
      final intent = await _parseUseCase.execute(transcript);
      state = state.copyWith(parsedIntent: intent);
      _evaluate(intent);
    } catch (_) {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        errorMessage: 'فشل في تحليل النص. حاول مرة أخرى.\nFailed to parse input. Please try again.',
      );
    }
  }

  void _evaluate(ParsedIntent intent) {
    if (intent.confidence >= 0.7 && !intent.clarificationNeeded) {
      state = state.copyWith(status: VoiceInputStatus.actionable);
    } else {
      final question = _clarificationUseCase.nextQuestion(intent);
      state = state.copyWith(
        status: VoiceInputStatus.clarifying,
        currentQuestion: question,
      );
    }
  }

  void applyClarification(ExtractedEntities updatedEntities) {
    final current = state.parsedIntent;
    if (current == null) return;
    final updated = _clarificationUseCase.applyAnswer(current, updatedEntities);
    state = state.copyWith(parsedIntent: updated);
    _evaluate(updated);
  }

  void reset() {
    state = const VoiceInputState();
  }
}

final voiceInputProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
  return VoiceInputNotifier(
    ref.watch(parseVoiceInputUseCaseProvider),
    ref.watch(clarificationDialogueUseCaseProvider),
    AiChannel.instance,
  );
});
