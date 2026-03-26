import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/nlu/domain/entities/parsed_intent.dart';
import '../../../../features/reminder/application/voice_input_provider.dart';

class ClarificationScreen extends ConsumerStatefulWidget {
  final ParsedIntent initialIntent;
  const ClarificationScreen({super.key, required this.initialIntent});

  @override
  ConsumerState<ClarificationScreen> createState() =>
      _ClarificationScreenState();
}

class _ClarificationScreenState extends ConsumerState<ClarificationScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputProvider);
    final notifier = ref.read(voiceInputProvider.notifier);

    ref.listen<VoiceInputState>(voiceInputProvider, (_, next) {
      if (next.status == VoiceInputStatus.actionable) {
        context.go('/create-reminder', extra: next.parsedIntent);
      }
    });

    final question = state.currentQuestion?.questionText ?? '';
    final isProcessing = state.status == VoiceInputStatus.processing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('توضيح\nClarification'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            notifier.reset();
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              question,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _answerController,
              textDirection: TextDirection.rtl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'اكتب إجابتك / Type your answer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () {
                      final answer = _answerController.text.trim();
                      if (answer.isEmpty) return;
                      final question = state.currentQuestion;
                      final entities = ExtractedEntities(
                        title: question?.targetField == 'title' ? answer : null,
                        scheduledAt: question?.targetField == 'scheduled_at'
                            ? DateTime.tryParse(answer)
                            : null,
                      );
                      notifier.applyClarification(entities);
                      _answerController.clear();
                    },
              child: isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('تأكيد / Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
