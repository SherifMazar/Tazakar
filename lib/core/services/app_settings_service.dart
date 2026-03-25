import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common/sqlite_api.dart';

class AppSettingKeys {
  static const String firstLaunch = 'first_launch';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String snoozeDuration = 'snooze_duration';
}

class AppSettingsService {
  Future<String?> get(Database db, String key) async {
    final result = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  Future<void> set(Database db, String key, String value) async {
    await db.rawInsert(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
      [key, value],
    );
  }

  Future<bool> isFirstLaunch(Database db) async {
    final value = await get(db, AppSettingKeys.firstLaunch);
    return value == null || value == 'true';
  }

  Future<void> markLaunched(Database db) async {
    await set(db, AppSettingKeys.firstLaunch, 'false');
  }

  Future<ThemeMode> getThemeMode(Database db) async {
    final value = await get(db, AppSettingKeys.themeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(Database db, ThemeMode mode) async {
    final String strMode;
    switch (mode) {
      case ThemeMode.light:
        strMode = 'light';
        break;
      case ThemeMode.dark:
        strMode = 'dark';
        break;
      case ThemeMode.system:
        strMode = 'system';
        break;
    }
    await set(db, AppSettingKeys.themeMode, strMode);
  }

  Future<String> getLanguageCode(Database db) async {
    final value = await get(db, AppSettingKeys.languageCode);
    return value ?? 'ar';
  }

  Future<int> getSnoozeDuration(Database db) async {
    final value = await get(db, AppSettingKeys.snoozeDuration);
    if (value != null) {
      return int.tryParse(value) ?? 10;
    }
    return 10;
  }
}

final appSettingsServiceProvider = Provider<AppSettingsService>((ref) {
  return AppSettingsService();
});
