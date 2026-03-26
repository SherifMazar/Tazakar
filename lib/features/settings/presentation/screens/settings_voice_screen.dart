import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsVoiceScreen extends ConsumerWidget {
  const SettingsVoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tealColor = Color(0xFF2E7D8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Voice & AI',
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
            leading: const Icon(Icons.record_voice_over_rounded, color: tealColor),
            title: const Text(
              'AI Voice Gender',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'female',
                  icon: Icon(Icons.female_rounded),
                  label: Text('Female'),
                ),
                ButtonSegment(
                  value: 'male',
                  icon: Icon(Icons.male_rounded),
                  label: Text('Male'),
                ),
              ],
              selected: const {'female'},
              onSelectionChanged: (_) {},
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.noise_control_off_rounded, color: tealColor),
            title: Text(
              'Noise Filtering',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              'RNNoise on-device filtering',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: Switch(
              value: true,
              onChanged: null,
              activeColor: tealColor,
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.translate_rounded, color: tealColor),
            title: Text(
              'Dialect Detection',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              'Auto-detected from your speech',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            trailing: Icon(Icons.auto_awesome_rounded, color: tealColor),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.speed_rounded, color: tealColor),
            title: Text(
              'Voice Speed',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              '0.75× – 1.5× control — coming in Sprint 3.9',
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
