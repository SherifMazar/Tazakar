import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tazakar/core/database/database_service.dart';
import 'package:tazakar/core/router/app_router.dart';
import 'package:tazakar/core/theme/app_theme.dart';

/// نقطة دخول التطبيق
/// async لأننا نحتاج انتظار تهيئة قاعدة البيانات قبل تشغيل الواجهة
void main() async {
  // ضروري قبل أي async code في main
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة قاعدة البيانات والتحقق منها
  final db = DatabaseService();
  final result = await db.verifyDatabase();
  debugPrint('🗄️ Tables: ${result['tables']}');
  debugPrint('📂 Categories: ${result['categories_count']}');

  runApp(const ProviderScope(child: TazakarApp()));
}

/// الwidget الجذر للتطبيق
/// ProviderScope يغلفها لتفعيل Riverpod في كل التطبيق
class TazakarApp extends StatelessWidget {
  const TazakarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'تذكر',
      debugShowCheckedModeBanner: false,
      // تطبيق الثيم الفاتح والداكن
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // go_router للتنقل بين الشاشات
      routerConfig: appRouter,
      // دعم العربية والإنجليزية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
    );
  }
}
