import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/constants/app_constants.dart';
import 'package:tazakar/core/router/app_router.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';
import 'package:tazakar/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise Firebase (Remote Config + Crashlytics only)
  await Firebase.initializeApp();

  // Pass Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Fetch MONETIZATION_ACTIVE flag before UI loads
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.setDefaults({
    AppConstants.monetizationActiveKey: false,
  });

  try {
    await remoteConfig.fetchAndActivate();
  } catch (_) {
    // Fail silently — default false is safe
  }

  // Eagerly initialise the encrypted SQLCipher database before any widget
  // renders. This guarantees DatabaseService is ready when the first route
  // mounts and prevents any FutureProvider loading state flash on startup.
  final container = ProviderContainer();
  await container.read(databaseServiceProvider.future);
  await NotificationService.instance.init();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TazakarApp(),
    ),
  );
}

class TazakarApp extends ConsumerWidget {
  const TazakarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tazakar',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        fontFamily: 'Cairo',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D8C),
        ),
        useMaterial3: true,
      ),
    );
  }
}
