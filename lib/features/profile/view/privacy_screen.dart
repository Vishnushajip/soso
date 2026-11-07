import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/cartoon_scaffold.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  Future<void> _openEmail(BuildContext context, {required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: Env.supportEmail,
      queryParameters: {'subject': subject},
    );
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      await Clipboard.setData(ClipboardData(text: Env.supportEmail));
      AppSnackBar.showInfo(context, 'Support email copied: ${Env.supportEmail}');
    }
  }

  Future<void> _openGooglePrivacy(BuildContext context) async {
    final uri = Uri.parse('https://policies.google.com/privacy');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showInfo(context, 'Visit policies.google.com/privacy');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CartoonScaffold(
      title: 'Privacy Policy',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Header / Summary Card
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.sColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Env.appName,
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 18,
                              color: AppColors.onSurface,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last Updated: November 2026',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.onSurfaceMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const InfoText(
                  'Welcome to SOS Arena ("we", "our", or "us"). We are committed to '
                  'protecting your privacy. This policy explains how we collect, '
                  'use, and safeguard your data when using the SOS Arena Android '
                  'application and web platform (https://playsos.web.app).',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 1. Data We Collect
          const SectionLabel(
            label: '1. Information We Collect',
            icon: Icons.privacy_tip_rounded,
          ),
          const SizedBox(height: 10),
          const GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoText(
                  'Google Sign-In: If you sign in with Google, we collect your '
                  'display name, email address, profile picture URL, and unique '
                  'Google user ID (UID).',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Guest Mode: If you play as a Guest, a random anonymous ID and '
                  'temporary alias are generated. We do not collect or store your '
                  'real name or email address in Guest Mode.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Gameplay Data: Match results, scores, moves, ratings, rankings, '
                  'and leaderboards needed to power real-time multiplayer.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'In-Game Messages: Messages sent in game rooms and animated emoji '
                  'reactions are processed solely for in-game communication.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Device & Push Tokens: Device model, OS version, and Firebase '
                  'Cloud Messaging (FCM) tokens used solely to send match updates '
                  'and friend challenge notifications.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Crash & Diagnostic Data: Non-identifying crash logs via Firebase '
                  'Crashlytics to fix technical bugs and ensure app stability.',
                  bullet: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. How We Use Information
          const SectionLabel(
            label: '2. How We Use Your Data',
            icon: Icons.verified_user_rounded,
          ),
          const SizedBox(height: 10),
          const GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoText('Facilitate real-time multiplayer matches & fair play', bullet: true),
                SizedBox(height: 10),
                InfoText('Maintain leaderboards, profile stats & match history', bullet: true),
                SizedBox(height: 10),
                InfoText('Deliver push notifications (can be disabled in Settings)', bullet: true),
                SizedBox(height: 10),
                InfoText('Detect, prevent, and address cheating, exploits, and bugs', bullet: true),
                SizedBox(height: 10),
                InfoText('Provide player support and process account requests', bullet: true),
                SizedBox(height: 10),
                InfoText('We never sell, rent, or trade your personal information', bullet: true),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Third-Party Services
          const SectionLabel(
            label: '3. Third-Party Services',
            icon: Icons.hub_rounded,
          ),
          const SizedBox(height: 10),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InfoText(
                  'We integrate trusted third-party SDKs provided by Google/Firebase '
                  'to deliver core functionality:',
                ),
                const SizedBox(height: 10),
                const InfoText('Google Play Services (Authentication & Services)', bullet: true),
                const SizedBox(height: 8),
                const InfoText('Firebase Authentication (Secure user sign-in)', bullet: true),
                const SizedBox(height: 8),
                const InfoText('Cloud Firestore (Real-time gameplay database)', bullet: true),
                const SizedBox(height: 8),
                const InfoText('Firebase Cloud Messaging (FCM push notifications)', bullet: true),
                const SizedBox(height: 8),
                const InfoText('Firebase Crashlytics & Analytics (Stability & diagnostics)', bullet: true),
                const SizedBox(height: 14),
                AppButton(
                  label: 'View Google Privacy Policy',
                  icon: Icons.open_in_new_rounded,
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: () => _openGooglePrivacy(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Account & Data Deletion (Play Store Mandatory)
          const SectionLabel(
            label: '4. Account & Data Deletion',
            icon: Icons.delete_forever_rounded,
          ),
          const SizedBox(height: 10),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InfoText(
                  'Under Google Play Store policies, you have the right to request '
                  'the permanent deletion of your account and all associated personal data.',
                ),
                const SizedBox(height: 12),
                const InfoText(
                  'How to Request Deletion: Send an email from your registered Google '
                  'account to info.playsoso@gmail.com with the subject line '
                  '"Account Deletion Request".',
                  bullet: true,
                ),
                const SizedBox(height: 10),
                const InfoText(
                  'What Gets Deleted: Your personal profile, email, display name, '
                  'profile picture, device tokens, friend lists, chat logs, and '
                  'leaderboard records will be permanently erased within 30 days.',
                  bullet: true,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Request Account Deletion',
                  icon: Icons.delete_outline_rounded,
                  variant: AppButtonVariant.danger,
                  expanded: true,
                  onPressed: () => _openEmail(context, subject: 'SOS Arena - Account Deletion Request'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 5. Data Security & Retention
          const SectionLabel(
            label: '5. Security & Retention',
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 10),
          const GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoText(
                  'Encryption: All network traffic between your device and our servers '
                  'is encrypted in transit using industry-standard HTTPS / TLS.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Secure Infrastructure: Data is hosted in Google Cloud and Firebase '
                  'data centers protected by physical and digital access controls.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Retention Period: We retain data only as long as your account remains '
                  'active or as necessary to provide game services.',
                  bullet: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 6. Children's Privacy
          const SectionLabel(
            label: "6. Children's Privacy",
            icon: Icons.child_care_rounded,
          ),
          const SizedBox(height: 10),
          const GameCard(
            child: InfoText(
              'SOS Arena is not directed to children under 13 years of age (or under '
              '16 in the European Economic Area). We do not knowingly collect personal '
              'identifiable information from children under 13. If you believe a child '
              'has provided us with personal information, please contact us immediately '
              'at info.playsoso@gmail.com and we will promptly delete it.',
            ),
          ),
          const SizedBox(height: 18),

          // 7. Your Privacy Controls
          const SectionLabel(
            label: '7. Your Privacy Controls',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 10),
          const GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoText(
                  'Notifications: You can enable or disable push notifications at any '
                  'time through the in-app Settings screen or your device settings.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Guest Mode: You can play offline or online without providing an '
                  'email address or Google profile.',
                  bullet: true,
                ),
                SizedBox(height: 10),
                InfoText(
                  'Data Inquiries: You may contact us at any time to review, correct, '
                  'or export your stored game records.',
                  bullet: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 8. Contact Information
          const SectionLabel(
            label: '8. Contact Us',
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 10),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InfoText(
                  'If you have any questions, feedback, or data privacy requests, '
                  'please contact our team:',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_rounded, color: AppColors.sColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          Env.supportEmail,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Email Support',
                  icon: Icons.send_rounded,
                  expanded: true,
                  onPressed: () => _openEmail(context, subject: 'SOS Arena Privacy Inquiry'),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Copy Email Address',
                  icon: Icons.copy_rounded,
                  variant: AppButtonVariant.secondary,
                  expanded: true,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: Env.supportEmail));
                    if (context.mounted) {
                      AppSnackBar.showSuccess(context, 'Support email copied');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
