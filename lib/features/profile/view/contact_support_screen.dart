import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/cartoon_scaffold.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CartoonScaffold(
      title: 'Support',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionLabel(label: 'Get In Touch', icon: Icons.support_agent_rounded),
          const SizedBox(height: 10),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InfoText(
                  'Have a question, found a bug, or need help with your '
                  'account? Reach out and we typically reply within 24 hours.',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.sColor.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.sColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.email_rounded,
                          color: AppColors.sColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support email',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              Env.supportEmail,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.sColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            icon: Icons.send_rounded,
            label: 'Email support',
            expanded: true,
            onPressed: () => _openMail(context),
          ),
          const SizedBox(height: 10),
          AppButton(
            icon: Icons.copy_rounded,
            label: 'Copy email address',
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: Env.supportEmail),
              );
              if (context.mounted) {
                _snack(context, 'Email address copied');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openMail(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: Env.supportEmail,
      queryParameters: {'subject': 'SOS Arena Support'},
    );
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: Env.supportEmail));
      messenger.showSnackBar(
        const SnackBar(content: Text('No mail app found — email copied instead')),
      );
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
