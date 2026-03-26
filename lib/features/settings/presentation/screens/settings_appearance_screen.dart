import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/providers/theme_provider.dart';
import 'package:tazakar/core/providers/locale_provider.dart';

class SettingsAppearanceScreen extends ConsumerWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tealColor = Color(0xFF2E7D8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appearance',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: tealColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded, color: tealColor),
            title: const Text(
              'Theme',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded),
                  label: Text('Dark'),
                ),
              ],
              selected: {ref.watch(resolvedThemeModeProvider)},
              onSelectionChanged: (val) => ref.read(themeModeProvider.notifier).setThemeMode(val.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded, color: tealColor),
            title: const Text(
              'Language',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'ar',
                  label: Text('العربية'),
                ),
                ButtonSegment(
                  value: 'en',
                  label: Text('English'),
                ),
              ],
              selected: {ref.watch(resolvedLocaleProvider).languageCode},
              onSelectionChanged: (val) => ref.read(localeProvider.notifier).setLocale(val.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.access_time_rounded, color: tealColor),
            title: Text(
              'Time Format',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              '12-hour / 24-hour — coming in Sprint 3.9',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
