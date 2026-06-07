import 'package:flutter/material.dart';

import '../../../core/widgets/cartoon_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CartoonScaffold(
      title: 'Terms',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          SectionLabel(label: 'Fair Play', icon: Icons.handshake_rounded),
          SizedBox(height: 10),
          GameCard(
            child: InfoText(
              'By using SOS Arena you agree to play fair and respect other '
              'players. Cheating, exploiting bugs, or manipulating matches is '
              'not allowed.',
            ),
          ),
          SizedBox(height: 18),
          SectionLabel(label: 'Community Rules', icon: Icons.groups_rounded),
          SizedBox(height: 10),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoText('No abusive language or harassment', bullet: true),
                SizedBox(height: 10),
                InfoText('No cheating, botting, or third-party tools', bullet: true),
                SizedBox(height: 10),
                InfoText('Violations may lead to account suspension', bullet: true),
              ],
            ),
          ),
          SizedBox(height: 18),
          SectionLabel(label: 'Service', icon: Icons.info_outline_rounded),
          SizedBox(height: 10),
          GameCard(
            child: InfoText(
              'The service is provided "as-is" without warranties. We may update '
              'these terms over time; continued use means you accept the latest '
              'version.',
            ),
          ),
        ],
      ),
    );
  }
}
