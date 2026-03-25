import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';
import 'package:tazakar/features/splash/presentation/screens/splash_screen.dart';
import 'package:tazakar/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tazakar/features/reminders/presentation/screens/home_screen.dart';
import 'package:tazakar/features/reminders/presentation/screens/add_reminder_screen.dart';
import 'package:tazakar/features/reminders/presentation/screens/reminder_detail_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_voice_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_appearance_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_notifications_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_privacy_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_about_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String addReminder = '/add-reminder';
  static const String reminderDetail = '/reminder/:id';
  static const String settings = '/settings';
  static const String settingsVoice = '/settings/voice';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsAbout = '/settings/about';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      if (state.uri.path != AppRoutes.splash) {
        return null;
      }

      final dbState = ref.read(databaseServiceProvider);
      final db = dbState.valueOrNull;

      if (db == null) {
        return null;
      }

      final service = ref.read(appSettingsServiceProvider);
      final isFirstLaunch = await service.isFirstLaunch(db.db);

      if (isFirstLaunch) {
        return AppRoutes.onboarding;
      } else {
        return AppRoutes.home;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
        routes: [
          GoRoute(
            path: 'voice',
            name: 'settingsVoice',
            builder: (context, state) => const SettingsVoiceScreen(),
          ),
          GoRoute(
            path: 'appearance',
            name: 'settingsAppearance',
            builder: (context, state) => const SettingsAppearanceScreen(),
          ),
          GoRoute(
            path: 'notifications',
            name: 'settingsNotifications',
            builder: (context, state) => const SettingsNotificationsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            name: 'settingsPrivacy',
            builder: (context, state) => const SettingsPrivacyScreen(),
          ),
          GoRoute(
            path: 'about',
            name: 'settingsAbout',
            builder: (context, state) => const SettingsAboutScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});
