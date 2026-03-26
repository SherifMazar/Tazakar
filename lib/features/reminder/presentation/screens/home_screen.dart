import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';
import 'package:tazakar/infrastructure/platform/ai_channel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Home — Coming Soon'),

            const SizedBox(height: 16),

            // ── AQ-04 SQLCipher Benchmark Button (remove after S3.3) ──
            ElevatedButton(
              onPressed: () async {
                try {
                  final db = await ref.read(databaseServiceProvider.future);
                  const iterations = 100;
                  final stopwatch = Stopwatch()..start();
                  for (int i = 0; i < iterations; i++) {
                    await db.query('app_settings');
                  }
                  stopwatch.stop();
                  final totalMs = stopwatch.elapsedMilliseconds;
                  final avgMs = totalMs / iterations;
                  debugPrint(
                    '[AQ-04] SQLCipher benchmark: '
                    '$iterations queries in ${totalMs}ms — '
                    'avg ${avgMs.toStringAsFixed(2)}ms per query',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'AQ-04: avg ${avgMs.toStringAsFixed(2)}ms/query',
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Benchmark SQLCipher (AQ-04)'),
            ),

            const SizedBox(height: 16),

            // ── Objective 4: Platform Channel Test (remove after S3.3) ──
            ElevatedButton(
              onPressed: () async {
                try {
                  final channel = AiChannel.instance;
                  final loaded = await channel.loadModel();
                  final ready = await channel.isModelLoaded();
                  debugPrint('[Obj4] loadModel=$loaded isModelLoaded=$ready');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Channel OK — loadModel=$loaded isModelLoaded=$ready',
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('[Obj4] Error: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Channel Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Test AI Channel (Obj4)'),
            ),
            // ── End Objective 4 Test ──
          ],
        ),
      ),
    );
  }
}
