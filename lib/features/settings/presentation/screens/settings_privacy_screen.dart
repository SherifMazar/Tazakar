import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPrivacyScreen extends ConsumerWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tealColor = Color(0xFF2E7D8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy & Data',
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
            leading: Icon(Icons.lock_rounded, color: tealColor),
            title: Text(
              'All Data On-Device',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              'AES-256 encrypted · zero cloud · zero accounts',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: Icon(Icons.verified_rounded, color: Colors.green),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_rounded, color: tealColor),
            title: const Text(
              'Export All Data',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: const Text(
              'Coming in Sprint 3.9',
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
                  content: Text('Data export coming in Sprint 3.9'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: const Text(
              'Delete All Data',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.red,
              ),
            ),
            subtitle: const Text(
              'Permanently erases all reminders and settings',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Delete All Data?',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    content: const Text(
                      'This action cannot be undone. All reminders and settings will be permanently erased.',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.policy_rounded, color: tealColor),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
