// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_update_providers.dart';
import '../../../core/providers/service_providers.dart';

final soundEnabledSettingProvider = StateProvider<bool>((ref) {
  return ref.watch(soundServiceProvider).soundEnabled;
});
final soundVolumeSettingProvider = StateProvider<double>((ref) {
  return ref.watch(soundServiceProvider).soundVolume;
});
final musicEnabledSettingProvider = StateProvider<bool>((ref) {
  return ref.watch(soundServiceProvider).musicEnabled;
});
final musicVolumeSettingProvider = StateProvider<double>((ref) {
  return ref.watch(soundServiceProvider).musicVolume;
});
final hapticsEnabledSettingProvider = StateProvider<bool>((ref) {
  return ref.watch(hapticServiceProvider).enabled;
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sound = ref.watch(soundEnabledSettingProvider);
    final soundVolume = ref.watch(soundVolumeSettingProvider);
    final music = ref.watch(musicEnabledSettingProvider);
    final musicVolume = ref.watch(musicVolumeSettingProvider);
    final haptics = ref.watch(hapticsEnabledSettingProvider);

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
                color: AppColors.primary.withValues(alpha: 0.18),
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
                  icon: Icons.library_music_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Theme Music',
                  subtitle: 'Continuous background theme',
                  value: music,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    ref.read(musicEnabledSettingProvider.notifier).state = v;
                    await ref.read(soundServiceProvider).setMusicEnabled(v);
                  },
                ),
                if (music)
                  _VolumeSliderRow(
                    icon: musicVolume == 0
                        ? Icons.volume_off_rounded
                        : (musicVolume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded),
                    iconColor: AppColors.secondary,
                    label: 'Music Volume',
                    value: musicVolume,
                    onChanged: (v) async {
                      ref.read(musicVolumeSettingProvider.notifier).state = v;
                      await ref.read(soundServiceProvider).setMusicVolume(v);
                    },
                  ),
                const _Divider(),
                _ToggleRow(
                  icon: Icons.sports_esports_rounded,
                  iconColor: AppColors.sColor,
                  title: 'Sound Effects',
                  subtitle: 'Buttons, moves & notifications',
                  value: sound,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    ref.read(soundEnabledSettingProvider.notifier).state = v;
                    await ref.read(soundServiceProvider).setSoundEnabled(v);
                  },
                ),
                if (sound)
                  _VolumeSliderRow(
                    icon: soundVolume == 0
                        ? Icons.volume_off_rounded
                        : (soundVolume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded),
                    iconColor: AppColors.sColor,
                    label: 'SFX Volume',
                    value: soundVolume,
                    onChanged: (v) async {
                      ref.read(soundVolumeSettingProvider.notifier).state = v;
                      await ref.read(soundServiceProvider).setSoundVolume(v);
                    },
                  ),
                const _Divider(),
                _ToggleRow(
                  icon: Icons.vibration_rounded,
                  iconColor: AppColors.oColor,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibration on taps, scores & wins',
                  value: haptics,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    ref.read(hapticsEnabledSettingProvider.notifier).state = v;
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 54,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: value
              ? color
              : AppColors.onSurfaceMuted.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.6)
                : AppColors.onSurfaceMuted.withValues(alpha: 0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: value
                  ? color.withValues(alpha: 0.35)
                  : Colors.transparent,
              blurRadius: value ? 8 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              value ? Icons.check_rounded : Icons.close_rounded,
              size: 13,
              color: value
                  ? color
                  : AppColors.onSurfaceMuted.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
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
                  AppColors.primary.withValues(alpha: 0.3),
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

class _VolumeSliderRow extends StatelessWidget {
  const _VolumeSliderRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.20),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pct%',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 12,
                      color: iconColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: iconColor,
                inactiveTrackColor: iconColor.withValues(alpha: 0.22),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                overlayColor: iconColor.withValues(alpha: 0.20),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                trackHeight: 6,
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (v) {
                  onChanged(v.clamp(0.0, 1.0));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

