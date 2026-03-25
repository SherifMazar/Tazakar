import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final dbService = await ref.watch(databaseServiceProvider.future);
    final db = dbService.db;
    final service = ref.read(appSettingsServiceProvider);
    return await service.getThemeMode(db);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final dbService = await ref.read(databaseServiceProvider.future);
    final db = dbService.db;
    final service = ref.read(appSettingsServiceProvider);
    await service.setThemeMode(db, mode);
    state = AsyncData(mode);
  }
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(themeModeProvider).value;
  return mode ?? ThemeMode.system;
});
