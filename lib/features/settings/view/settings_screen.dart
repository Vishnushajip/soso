import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/env.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/service_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _sound = ref.read(soundServiceProvider).enabled;
  late bool _haptics = ref.read(hapticServiceProvider).enabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            SectionCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _sound,
                    onChanged: (v) async {
                      setState(() => _sound = v);
                      await ref.read(soundServiceProvider).setEnabled(v);
                    },
                    title: const Text('Sound effects'),
                    subtitle: const Text('SOS, scoring, notifications'),
                  ),
                  SwitchListTile(
                    value: _haptics,
                    onChanged: (v) async {
                      setState(() => _haptics = v);
                      await ref.read(hapticServiceProvider).setEnabled(v);
                    },
                    title: const Text('Haptic feedback'),
                    subtitle: const Text('Vibration on taps, scores and wins'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: ListTile(
                title: const Text('App version'),
                subtitle: Text('${Env.appName} · 1.0.0'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
