import 'package:flutter/material.dart';

import '../../../core/widgets/section_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SectionCard(
          child: SingleChildScrollView(
            child: Text(
              'We collect only the data needed to run the game: '
              'your Google profile (name, email, photo), gameplay statistics, '
              'and device tokens used for push notifications. We do not sell '
              'or share your personal information.\n\nYou can delete your account '
              'and associated data by emailing support.',
            ),
          ),
        ),
      ),
    );
  }
}
