import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsAboutScreen extends ConsumerWidget {
  const SettingsAboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tealColor = Color(0xFF2E7D8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
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
          const ListTile(
            leading: Icon(Icons.app_shortcut_rounded, color: tealColor),
            title: Text(
              'Tazakar',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Version 1.0.0 — MVP',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback_rounded, color: tealColor),
            title: const Text(
              'Send Feedback',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback module coming in Sprint 4.3'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rounded, color: tealColor),
            title: const Text(
              'Rate Tazakar',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rate on App Store / Google Play — coming at launch'),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_giftcard_rounded, color: tealColor),
            title: const Text(
              'Unlock Code',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'Have a promo code? Enter it here',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Promo code entry — coming in Sprint 4.4'),
                ),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
