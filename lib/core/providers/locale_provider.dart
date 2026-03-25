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
    final languageCode = await service.getLanguageCode(db);
    return Locale(languageCode);
  }

  Future<void> setLocale(String languageCode) async {
    final dbService = await ref.read(databaseServiceProvider.future);
    final db = dbService.db;
    final service = ref.read(appSettingsServiceProvider);
    await service.set(db, AppSettingKeys.languageCode, languageCode);
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
