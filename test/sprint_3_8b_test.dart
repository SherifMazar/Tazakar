import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';
import 'package:tazakar/core/providers/theme_provider.dart';
import 'package:tazakar/core/providers/locale_provider.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_appearance_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_notifications_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_voice_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_privacy_screen.dart';
import 'package:tazakar/features/settings/presentation/screens/settings_about_screen.dart';

class FakeAppSettingsService extends AppSettingsService {
  @override
  Future<int> getSnoozeDuration(Database db) async => 10;

  @override
  Future<bool> isFirstLaunch(Database db) async => false;
}

class FakeThemeNotifier extends ThemeNotifier {
  @override
  Future<ThemeMode> build() async => ThemeMode.light;
}

class FakeLocaleNotifier extends LocaleNotifier {
  @override
  Future<Locale> build() async => const Locale('ar');
}

Widget buildTestable(Widget child) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWith((ref) async => throw UnimplementedError()),
      appSettingsServiceProvider.overrideWithValue(FakeAppSettingsService()),
      themeModeProvider.overrideWith(FakeThemeNotifier.new),
      localeProvider.overrideWith(FakeLocaleNotifier.new),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

Widget buildRouterTestable(GoRouter router) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWith((ref) async => throw UnimplementedError()),
      appSettingsServiceProvider.overrideWithValue(FakeAppSettingsService()),
      themeModeProvider.overrideWith(FakeThemeNotifier.new),
      localeProvider.overrideWith(FakeLocaleNotifier.new),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('Group A — SettingsScreen', () {
    testWidgets('Renders properly', (tester) async {
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/settingsVoice', name: 'settingsVoice', builder: (_, __) => const Scaffold()),
          GoRoute(path: '/settingsAppearance', name: 'settingsAppearance', builder: (_, __) => const Scaffold()),
          GoRoute(path: '/settingsNotifications', name: 'settingsNotifications', builder: (_, __) => const Scaffold()),
          GoRoute(path: '/settingsPrivacy', name: 'settingsPrivacy', builder: (_, __) => const Scaffold()),
          GoRoute(path: '/settingsAbout', name: 'settingsAbout', builder: (_, __) => const Scaffold()),
        ],
      );

      await tester.pumpWidget(buildRouterTestable(router));

      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('ABOUT & PRIVACY'), findsOneWidget);
      
      expect(find.text('Voice & AI'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy & Data'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });
  });

  group('Group B — SettingsAppearanceScreen', () {
    testWidgets('Renders properly', (tester) async {
      await tester.pumpWidget(buildTestable(const SettingsAppearanceScreen()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Appearance'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Time Format'), findsOneWidget);

      final segments = tester.widgetList(
        find.byWidgetPredicate((widget) => widget is SegmentedButton),
      ).toList();
      
      expect(segments.length, 2);
      expect((segments[0] as SegmentedButton).segments.length, 3);
      expect((segments[1] as SegmentedButton).segments.length, 2);
    });
  });

  group('Group C — SettingsNotificationsScreen', () {
    testWidgets('Renders properly', (tester) async {
      final completer = Completer<DatabaseService>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWith((ref) => completer.future),
            appSettingsServiceProvider.overrideWithValue(FakeAppSettingsService()),
            themeModeProvider.overrideWith(FakeThemeNotifier.new),
            localeProvider.overrideWith(FakeLocaleNotifier.new),
          ],
          child: const MaterialApp(
            home: SettingsNotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Notifications'), findsOneWidget);
      expect(find.text('Snooze Duration'), findsOneWidget);
      expect(find.text('Reminder Sound'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);

      final dropdowns = tester.widgetList(
        find.byWidgetPredicate((widget) => widget is DropdownButton),
      ).toList();
      expect(dropdowns.length, 1);
      expect((dropdowns.first as DropdownButton).items?.length, 5);
    });
  });

  group('Group D — SettingsVoiceScreen', () {
    testWidgets('Renders properly', (tester) async {
      await tester.pumpWidget(buildTestable(const SettingsVoiceScreen()));

      expect(find.widgetWithText(AppBar, 'Voice & AI'), findsOneWidget);
      expect(find.text('AI Voice Gender'), findsOneWidget);
      expect(find.text('Noise Filtering'), findsOneWidget);
      expect(find.text('Dialect Detection'), findsOneWidget);
      expect(find.text('Voice Speed'), findsOneWidget);
    });
  });

  group('Group E — SettingsPrivacyScreen', () {
    testWidgets('Renders properly', (tester) async {
      await tester.pumpWidget(buildTestable(const SettingsPrivacyScreen()));

      expect(find.widgetWithText(AppBar, 'Privacy & Data'), findsOneWidget);
      expect(find.text('All Data On-Device'), findsOneWidget);
      expect(find.text('Export All Data'), findsOneWidget);
      expect(find.text('Delete All Data'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      await tester.tap(find.text('Export All Data'));
      await tester.pump(); 
      expect(find.text('Data export coming in Sprint 3.9'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.text('Delete All Data'));
      await tester.pumpAndSettle(); 
      expect(find.text('Delete All Data?'), findsOneWidget);
    });
  });

  group('Group F — SettingsAboutScreen', () {
    testWidgets('Renders properly', (tester) async {
      await tester.pumpWidget(buildTestable(const SettingsAboutScreen()));

      expect(find.widgetWithText(AppBar, 'About'), findsOneWidget);
      expect(find.text('Tazakar'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);
      expect(find.text('Rate Tazakar'), findsOneWidget);
      expect(find.text('Unlock Code'), findsOneWidget);
    });
  });
}
