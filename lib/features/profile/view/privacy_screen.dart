import 'package:flutter/material.dart';

import '../../../core/widgets/cartoon_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CartoonScaffold(
      title: 'Privacy',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          SectionLabel(label: 'What We Collect', icon: Icons.privacy_tip_rounded),
          SizedBox(height: 10),
          GameCard(
            child: InfoText(
              'We collect only the data needed to run the game: your Google '
              'profile (name, email, photo), gameplay statistics, and device '
              'tokens used for push notifications.',
            ),
          ),
          SizedBox(height: 18),
          SectionLabel(label: 'How We Use It', icon: Icons.shield_rounded),
          SizedBox(height: 10),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoText('We never sell or share your personal information', bullet: true),
                SizedBox(height: 10),
                InfoText('Stats power the leaderboard and your profile', bullet: true),
                SizedBox(height: 10),
                InfoText('Device tokens are used only to send you notifications', bullet: true),
              ],
            ),
          ),
          SizedBox(height: 18),
          SectionLabel(label: 'Your Data', icon: Icons.delete_outline_rounded),
          SizedBox(height: 10),
          GameCard(
            child: InfoText(
              'You can delete your account and all associated data at any time '
              'by emailing support from the Contact Support page.',
            ),
          ),
        ],
      ),
    );
  }
}
