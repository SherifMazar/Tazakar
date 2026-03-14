import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tazakar/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tazakar/features/reminders/presentation/screens/home_screen.dart';
import 'package:tazakar/features/reminders/presentation/screens/add_reminder_screen.dart';
import 'package:tazakar/features/reminders/presentation/screens/reminder_detail_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_screen.dart';

// Route path constants
class AppRoutes {
  AppRoutes._();
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String addReminder = '/add-reminder';
  static const String reminderDetail = '/reminder/:id';
  static const String settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.addReminder,
        name: 'addReminder',
        builder: (context, state) => const AddReminderScreen(),
      ),
      GoRoute(
        path: AppRoutes.reminderDetail,
        name: 'reminderDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReminderDetailScreen(reminderId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});
