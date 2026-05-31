import 'package:flutter/material.dart';

import '../../../core/widgets/section_card.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SectionCard(
          child: SingleChildScrollView(
            child: Text(
              'By using SOS Arena you agree to play fair, respect other players, '
              'and refrain from cheating, abusive language, or harassment. '
              'Violations may lead to account suspension. Service is provided as-is.',
            ),
          ),
        ),
      ),
    );
  }
}
