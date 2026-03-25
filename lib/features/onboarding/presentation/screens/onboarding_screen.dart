import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    try {
      await Permission.microphone.request();
      await Permission.notification.request();

      final dbService = await ref.read(databaseServiceProvider.future);
      final service = ref.read(appSettingsServiceProvider);
      await service.markLaunched(dbService.db);

      if (!mounted) return;
      context.goNamed('home');
    } catch (_) {
      if (!mounted) return;
      context.goNamed('home');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF2E7D8C);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: _currentPage < 2
                  ? TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                            color: tealColor, fontFamily: 'Cairo'),
                      ),
                    )
                  : const SizedBox(height: 48), // Spacer to prevent jitter
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  _OnboardingSlide(
                    icon: Icons.mic_rounded,
                    title: 'Speak Your Dialect',
                    subtitle:
                        'Gulf, Levantine, Egyptian, Maghrebi — just talk naturally',
                  ),
                  _OnboardingSlide(
                    icon: Icons.lock_rounded,
                    title: 'Privacy, Protected',
                    subtitle:
                        'All data stays on your device. Zero cloud. Zero accounts.',
                  ),
                  _OnboardingSlide(
                    icon: Icons.notifications_rounded,
                    title: 'Just Say Remind Me',
                    subtitle: 'We handle the rest — time, category, recurrence',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 10,
                        width: isActive ? 24 : 10,
                        decoration: BoxDecoration(
                          color: isActive ? tealColor : Colors.transparent,
                          border: Border.all(color: tealColor),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: const Color(0xFF2E7D8C),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
