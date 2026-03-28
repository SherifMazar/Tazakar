import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final dbService = await ref.watch(databaseServiceProvider.future);
    final db = dbService.db;
    final service = ref.read(appSettingsServiceProvider);
    final dialectCode = await service.getDialectPref(db);
    // dialect_pref stores dialect codes like 'ar-AE', 'ar-EG', or 'auto'.
    // Extract the language tag prefix for Locale (e.g. 'ar-AE' → 'ar').
    final langCode = dialectCode == 'auto' ? 'ar' : dialectCode.split('-').first;
    return Locale(langCode);
  }

  Future<void> setLocale(String languageCode) async {
    final dbService = await ref.read(databaseServiceProvider.future);
    final db = dbService.db;
    final service = ref.read(appSettingsServiceProvider);
    await service.setDialectPref(db, languageCode);
    state = AsyncData(Locale(languageCode));
  }
}

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

final resolvedLocaleProvider = Provider<Locale>((ref) {
  final asyncLocale = ref.watch(localeProvider).value;
  return asyncLocale ?? const Locale('ar');
});

final textDirectionProvider = Provider<TextDirection>((ref) {
  final locale = ref.watch(resolvedLocaleProvider);
  return locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
});
