import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/constants/app_constants.dart';
import 'package:tazakar/core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise Firebase (Remote Config + Crashlytics only)
  await Firebase.initializeApp();

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

  runApp(
    const ProviderScope(
      child: TazakarApp(),
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
