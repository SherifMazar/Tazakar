import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';
import 'package:tazakar/core/providers/theme_provider.dart';
import 'package:tazakar/core/providers/locale_provider.dart';
import 'package:tazakar/core/router/app_router.dart';
import 'package:tazakar/features/splash/presentation/screens/splash_screen.dart';
import 'package:tazakar/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tazakar/features/reminders/presentation/screens/home_screen.dart';

// Fakes
class FakeAppSettingsService extends AppSettingsService {
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

void main() {
  group('Group A — AppSettingsService', () {
    late Database db;
    late AppSettingsService service;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, _) async {
            await database.execute('''
              CREATE TABLE app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      service = AppSettingsService();
    });

    tearDown(() async {
      await db.delete('app_settings');
    });

    test('isFirstLaunch returns true when key is missing', () async {
      expect(await service.isFirstLaunch(db), isTrue);
    });

    test('isFirstLaunch returns true when value is \'true\'', () async {
      await service.set(db, AppSettingKeys.firstLaunch, 'true');
      expect(await service.isFirstLaunch(db), isTrue);
    });

    test('isFirstLaunch returns false when value is \'false\'', () async {
      await service.set(db, AppSettingKeys.firstLaunch, 'false');
      expect(await service.isFirstLaunch(db), isFalse);
    });

    test('getThemeMode returns ThemeMode.system by default', () async {
      expect(await service.getThemeMode(db), equals(ThemeMode.system));
    });

    test('getThemeMode returns ThemeMode.dark when value is \'dark\'', () async {
      await service.set(db, AppSettingKeys.themeMode, 'dark');
      expect(await service.getThemeMode(db), equals(ThemeMode.dark));
    });

    test('getThemeMode returns ThemeMode.light when value is \'light\'', () async {
      await service.set(db, AppSettingKeys.themeMode, 'light');
      expect(await service.getThemeMode(db), equals(ThemeMode.light));
    });

    test('getLanguageCode returns \'ar\' by default', () async {
      expect(await service.getLanguageCode(db), equals('ar'));
    });

    test('getSnoozeDuration returns 10 by default', () async {
      expect(await service.getSnoozeDuration(db), equals(10));
    });
  });

  group('Group B — SplashScreen widget tests', () {
    testWidgets('Renders app name, CircularProgressIndicator, Background color', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            name: 'splash',
            builder: (_, __) => const SplashScreen(),
          ),
          GoRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('home')),
            ),
          ),
          GoRoute(
            path: '/onboarding',
            name: 'onboarding',
            builder: (_, __) => const Scaffold(
              body: Center(child: Text('onboarding')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWith((ref) async => throw UnimplementedError()),
            appSettingsServiceProvider.overrideWithValue(FakeAppSettingsService()),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pump(); // let initState + postFrameCallback fire

      // Assert splash UI renders correctly before the timer fires
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(const Color(0xFF2E7D8C)));
      expect(find.text('تذكر'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Drain the 1500ms timer so _navigate() completes without leaving pending timers
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Group C — OnboardingScreen widget tests', () {
    testWidgets('Slides logic and bottom controls behave correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWith((ref) async => throw UnimplementedError()),
            appSettingsServiceProvider.overrideWithValue(FakeAppSettingsService()),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Slide 1
      expect(find.text('Speak Your Dialect'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Slide 2
      expect(find.text('Privacy, Protected'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Slide 3
      expect(find.text('Just Say Remind Me'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Skip'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Get Started'), findsOneWidget);
    });
  });

  group('Group D — HomeScreen widget tests', () {
    testWidgets('Renders AppBar, default tab, FAB, Categories tab, BottomNavigationBar items count', (tester) async {
      final mockRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appRouterProvider.overrideWith((ref) => mockRouter),
            themeModeProvider.overrideWith(FakeThemeNotifier.new),
            localeProvider.overrideWith(FakeLocaleNotifier.new),
          ],
          child: MaterialApp.router(
            routerConfig: mockRouter,
          ),
        ),
      );

      // AppBar title
      expect(find.widgetWithText(AppBar, 'تذكر'), findsOneWidget);
      
      // Default placeholder
      expect(find.text('Reminders'), findsWidgets);
      
      // FAB
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // Switch to Categories
      await tester.tap(find.text('Categories').first);
      await tester.pumpAndSettle();

      // Categories placeholder is now visible
      expect(find.text('Categories'), findsWidgets);

      // BottomNavigationBar has 3 items
      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.items.length, equals(3));
    });
  });
}
