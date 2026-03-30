import 'package:go_router/go_router.dart';
import 'package:tazakar/features/splash/presentation/screens/splash_screen.dart';
import 'package:tazakar/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tazakar/features/home/presentation/screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);
