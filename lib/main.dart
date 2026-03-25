import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/constants/app_constants.dart';
import 'package:tazakar/core/router/app_router.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';
import 'package:tazakar/core/providers/theme_provider.dart';
import 'package:tazakar/core/providers/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.setDefaults({AppConstants.monetizationActiveKey: false});
  try { await remoteConfig.fetchAndActivate(); } catch (_) {}
  final container = ProviderContainer();
  await container.read(databaseServiceProvider.future);
  await container.read(themeModeProvider.future);
  await container.read(localeProvider.future);
  runApp(UncontrolledProviderScope(container: container, child: const TazakarApp()));
}

class TazakarApp extends ConsumerWidget {
  const TazakarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(resolvedThemeModeProvider);
    final locale = ref.watch(resolvedLocaleProvider);

    return MaterialApp.router(
      title: 'Tazakar',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D8C)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Cairo',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D8C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
