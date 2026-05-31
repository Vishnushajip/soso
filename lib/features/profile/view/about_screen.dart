import 'package:flutter/material.dart';

import '../../../core/constants/env.dart';
import '../../../core/widgets/section_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Env.appName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Version 1.0.0'),
              const SizedBox(height: 12),
              const Text(
                'SOS Arena is a real-time multiplayer SOS game. '
                'Place letters, build combos, climb the leaderboards.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
