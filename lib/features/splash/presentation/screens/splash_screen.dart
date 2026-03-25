import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate();
    });
  }

  Future<void> _navigate() async {
    try {
      final checkDbFuture = () async {
        final dbService = await ref.read(databaseServiceProvider.future);
        final service = ref.read(appSettingsServiceProvider);
        return await service.isFirstLaunch(dbService.db);
      }();

      final results = await Future.wait([
        checkDbFuture,
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);

      if (!mounted) return;

      final bool isFirstLaunch = results[0] as bool;
      if (isFirstLaunch) {
        context.goNamed('onboarding');
      } else {
        context.goNamed('home');
      }
    } catch (e) {
      if (!mounted) return;
      context.goNamed('home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D8C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'تذكر',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
