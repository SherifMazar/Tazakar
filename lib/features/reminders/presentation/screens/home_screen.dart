import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/services/notification_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

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
            const SizedBox(height: 32),

            // ── AQ-03 Doze Test Button (remove after S3.3) ──
            ElevatedButton(
              onPressed: () async {
                try {
                  final scheduledAt = DateTime.now().add(
                    const Duration(seconds: 15),
                  );
                  await NotificationService.instance.scheduleNotificationOnly(
                    reminderId: 999,
                    title: 'تذكر — اختبار',
                    body: 'إشعار اختباري — Doze test ✅',
                    scheduledAt: scheduledAt,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notification scheduled — lock the screen now!',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('[AQ-03 Test] Error: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Test Notification (15s)'),
            ),
            // ── End AQ-03 Test ──

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
                          'AQ-04: avg ${avgMs.toStringAsFixed(2)}ms/query '
                          '(${totalMs}ms total for $iterations queries)',
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('[AQ-04 Test] Error: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Benchmark SQLCipher (AQ-04)'),
            ),
            // ── End AQ-04 Test ──
          ],
        ),
      ),
    );
  }
}
