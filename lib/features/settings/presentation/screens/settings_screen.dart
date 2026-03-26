import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tealColor = Color(0xFF2E7D8C);

    Widget buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Cairo',
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Widget buildTile({
      required IconData icon,
      required String title,
      required String routeName,
    }) {
      return ListTile(
        leading: Icon(icon, color: tealColor),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => context.goNamed(routeName),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: tealColor,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          buildSectionHeader('PREFERENCES'),
          buildTile(
            icon: Icons.mic_rounded,
            title: 'Voice & AI',
            routeName: 'settingsVoice',
          ),
          buildTile(
            icon: Icons.palette_rounded,
            title: 'Appearance',
            routeName: 'settingsAppearance',
          ),
          buildTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            routeName: 'settingsNotifications',
          ),
          const Divider(),
          buildSectionHeader('ABOUT & PRIVACY'),
          buildTile(
            icon: Icons.lock_rounded,
            title: 'Privacy & Data',
            routeName: 'settingsPrivacy',
          ),
          buildTile(
            icon: Icons.info_rounded,
            title: 'About',
            routeName: 'settingsAbout',
          ),
        ],
      ),
    );
  }
}
