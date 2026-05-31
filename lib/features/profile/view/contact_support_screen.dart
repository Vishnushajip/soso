import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/section_card.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('We typically reply within 24 hours.'),
              const SizedBox(height: 12),
              Text(
                Env.supportEmail,
                style: const TextStyle(color: AppColors.sColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              AppButton(
                icon: Icons.copy,
                label: 'Copy email',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: Env.supportEmail));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email address copied')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
