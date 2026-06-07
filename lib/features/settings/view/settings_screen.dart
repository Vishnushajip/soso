import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_update_providers.dart';
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SectionLabel(
            label: 'Game Audio',
            icon: Icons.volume_up_rounded,
          ),
          const SizedBox(height: 10),
          _GameCard(
            child: Column(
              children: [
                _ToggleRow(
                  icon: Icons.music_note_rounded,
                  iconColor: AppColors.sColor,
                  title: 'Sound Effects',
                  subtitle: 'SOS, scoring & notifications',
                  value: _sound,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    setState(() => _sound = v);
                    await ref.read(soundServiceProvider).setEnabled(v);
                  },
                ),
                _Divider(),
                _ToggleRow(
                  icon: Icons.vibration_rounded,
                  iconColor: AppColors.oColor,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibration on taps, scores & wins',
                  value: _haptics,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    setState(() => _haptics = v);
                    await ref.read(hapticServiceProvider).setEnabled(v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'About', icon: Icons.info_rounded),
          const SizedBox(height: 10),
          _GameCard(
            child: Row(
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
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Env.appName,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 16,
                          color: AppColors.onSurface,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Consumer(
                        builder: (context, ref, _) {
                          final label = ref.watch(appVersionLabelProvider);
                          return Text(
                            label.isEmpty ? 'Version …' : 'Version $label',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.onSurfaceMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Latest',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: iconColor.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 14,
                    color: AppColors.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _CartoonSwitch(value: value, color: iconColor, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CartoonSwitch extends StatelessWidget {
  const _CartoonSwitch({
    required this.value,
    required this.color,
    required this.onChanged,
  });
  final bool value;
  final Color color;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: 54,
        height: 30,
        decoration: BoxDecoration(
          gradient: value
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: value ? null : AppColors.onSurfaceMuted.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: value
                ? color.withOpacity(0.5)
                : AppColors.onSurfaceMuted.withOpacity(0.25),
            width: 2,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: value
                    ? Icon(Icons.check_rounded, size: 13, color: color)
                    : Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: AppColors.onSurfaceMuted.withOpacity(0.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primary.withOpacity(0.10),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.luckiestGuy(
            fontSize: 13,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}
