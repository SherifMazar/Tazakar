import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tazakar/core/services/app_settings_service.dart';
import 'package:tazakar/infrastructure/database/database_service.dart';

class SettingsNotificationsScreen extends ConsumerStatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  ConsumerState<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends ConsumerState<SettingsNotificationsScreen> {
  int _snoozeDuration = 10;

  @override
  void initState() {
    super.initState();
    _loadSnoozeDuration();
  }

  Future<void> _loadSnoozeDuration() async {
    final dbService = await ref.read(databaseServiceProvider.future);
    final service = ref.read(appSettingsServiceProvider);
    final duration = await service.getSnoozeDuration(dbService.db);
    if (mounted) {
      setState(() {
        _snoozeDuration = duration;
      });
    }
  }

  Future<void> _updateSnoozeDuration(int? value) async {
    if (value == null) return;
    setState(() {
      _snoozeDuration = value;
    });
    // Note: snooze duration is now a per-reminder field.
    // Global default is kept as local UI state only.
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF2E7D8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
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
            leading: const Icon(Icons.snooze_rounded, color: tealColor),
            title: const Text(
              'Snooze Duration',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            trailing: DropdownButton<int>(
              value: _snoozeDuration,
              items: [5, 10, 15, 30, 60]
                  .map((val) => DropdownMenuItem<int>(
                        value: val,
                        child: Text(
                          '$val min',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ))
                  .toList(),
              onChanged: _updateSnoozeDuration,
              underline: const SizedBox(), 
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.volume_up_rounded, color: tealColor),
            title: Text(
              'Reminder Sound',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              'Custom sounds — coming in Sprint 4.2',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.vibration_rounded, color: tealColor),
            title: Text(
              'Vibration',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              'Vibration control — coming in Sprint 4.2',
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
