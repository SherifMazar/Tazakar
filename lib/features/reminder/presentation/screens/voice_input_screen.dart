import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/voice_input_provider.dart';
import '../widgets/waveform_widget.dart';

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceInputProvider);
    final notifier = ref.read(voiceInputProvider.notifier);

    ref.listen<VoiceInputState>(voiceInputProvider, (_, next) {
      if (next.status == VoiceInputStatus.actionable) {
        context.push('/clarification', extra: next.parsedIntent);
      }
      if (next.status == VoiceInputStatus.clarifying) {
        context.push('/clarification', extra: next.parsedIntent);
      }
    });

    final isRecording = state.status == VoiceInputStatus.recording;
    final isProcessing = state.status == VoiceInputStatus.processing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل تذكير\nNew Reminder'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showTextInput ? Icons.mic : Icons.keyboard),
            tooltip: _showTextInput ? 'الميكروفون' : 'لوحة المفاتيح',
            onPressed: () => setState(() => _showTextInput = !_showTextInput),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.errorMessage != null)
              _ErrorBanner(message: state.errorMessage!),
            const Spacer(),
            if (!_showTextInput) ...[
              WaveformWidget(isRecording: isRecording),
              const SizedBox(height: 32),
              _MicButton(
                isRecording: isRecording,
                isProcessing: isProcessing,
                onTap: () async {
                  if (isRecording) {
                    await notifier.stopAndTranscribe();
                  } else {
                    await notifier.startRecording();
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                isRecording
                    ? 'اضغط للإيقاف\nTap to stop'
                    : isProcessing
                        ? 'جارٍ المعالجة...\nProcessing...'
                        : 'اضغط للتحدث\nTap to speak',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              TextField(
                controller: _textController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'اكتب تذكيرك هنا / Type your reminder here',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () => notifier.onTextInput(_textController.text),
                child: const Text('إرسال / Submit'),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onTap;

  const _MicButton({
    required this.isRecording,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? Colors.red : color,
          boxShadow: isRecording
              ? [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 20)]
              : [],
        ),
        child: isProcessing
            ? const Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 40,
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
