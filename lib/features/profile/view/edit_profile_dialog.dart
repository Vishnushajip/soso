import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/customization/avatar_frame.dart';
import '../../../core/models/app_user.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/user_avatar.dart';

class AvatarPreset {
  final String label;
  final String url;
  const AvatarPreset({required this.label, required this.url});
}

const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset(
    label: 'Felix',
    url: 'https://api.dicebear.com/7.x/adventurer/png?seed=Felix',
  ),
  AvatarPreset(
    label: 'Aneka',
    url: 'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka',
  ),
  AvatarPreset(
    label: 'Zack',
    url: 'https://api.dicebear.com/7.x/adventurer/png?seed=Zack',
  ),
  AvatarPreset(
    label: 'Precious',
    url: 'https://api.dicebear.com/7.x/adventurer/png?seed=Precious',
  ),
  AvatarPreset(
    label: 'Chester',
    url: 'https://api.dicebear.com/7.x/adventurer/png?seed=Chester',
  ),
  AvatarPreset(
    label: 'Trouble',
    url: 'https://api.dicebear.com/7.x/adventurer/png?seed=Trouble',
  ),
  AvatarPreset(
    label: 'Cosmo',
    url: 'https://api.dicebear.com/7.x/bottts/png?seed=Cosmo',
  ),
  AvatarPreset(
    label: 'Sparky',
    url: 'https://api.dicebear.com/7.x/bottts/png?seed=Sparky',
  ),
  AvatarPreset(
    label: 'Turbo',
    url: 'https://api.dicebear.com/7.x/bottts/png?seed=Turbo',
  ),
  AvatarPreset(
    label: 'Blaze',
    url: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Blaze',
  ),
  AvatarPreset(
    label: 'Shadow',
    url: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Shadow',
  ),
  AvatarPreset(
    label: 'Star',
    url: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Star',
  ),
];

class EditProfileState {
  final String name;
  final String? photoUrl;
  final Uint8List? localPhotoBytes;
  final bool removePhoto;
  final bool isUploading;
  final bool isSaving;
  final bool showPresets;

  const EditProfileState({
    required this.name,
    this.photoUrl,
    this.localPhotoBytes,
    this.removePhoto = false,
    this.isUploading = false,
    this.isSaving = false,
    this.showPresets = false,
  });

  EditProfileState copyWith({
    String? name,
    String? Function()? photoUrl,
    Uint8List? Function()? localPhotoBytes,
    bool? removePhoto,
    bool? isUploading,
    bool? isSaving,
    bool? showPresets,
  }) {
    return EditProfileState(
      name: name ?? this.name,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      localPhotoBytes:
          localPhotoBytes != null ? localPhotoBytes() : this.localPhotoBytes,
      removePhoto: removePhoto ?? this.removePhoto,
      isUploading: isUploading ?? this.isUploading,
      isSaving: isSaving ?? this.isSaving,
      showPresets: showPresets ?? this.showPresets,
    );
  }
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  EditProfileNotifier(this.ref, this.user)
      : super(EditProfileState(name: user.name, photoUrl: user.photoUrl));

  final Ref ref;
  final AppUser user;

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void togglePresets() {
    state = state.copyWith(showPresets: !state.showPresets);
  }

  void selectPreset(String url) {
    state = state.copyWith(
      photoUrl: () => url,
      localPhotoBytes: () => null,
      removePhoto: false,
    );
    ref.read(userRepositoryProvider).updateProfile(
          uid: user.uid,
          photoUrl: url,
        );
    ref.invalidate(currentUserProvider);
    ref.read(hapticServiceProvider).fire(HapticEvent.selection);
  }

  void removePhoto() {
    state = state.copyWith(
      photoUrl: () => null,
      localPhotoBytes: () => null,
      removePhoto: true,
    );
    ref.read(userRepositoryProvider).updateProfile(
          uid: user.uid,
          removePhoto: true,
        );
    ref.invalidate(currentUserProvider);
    ref.read(hapticServiceProvider).fire(HapticEvent.tap);
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 80,
      );
      if (picked == null) return;

      state = state.copyWith(isUploading: true);
      final bytes = await picked.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Immediately persist to Firestore profile so it's not lost
      await ref.read(userRepositoryProvider).updateProfile(
            uid: user.uid,
            photoUrl: dataUrl,
          );
      ref.invalidate(currentUserProvider);

      // Also upload to Firebase Storage as background backup
      unawaited(
        ref
            .read(storageServiceProvider)
            .uploadAvatar(uid: user.uid, bytes: bytes)
            .catchError((_) => ''),
      );

      state = state.copyWith(
        photoUrl: () => dataUrl,
        localPhotoBytes: () => bytes,
        removePhoto: false,
        isUploading: false,
      );

      ref.read(hapticServiceProvider).fire(HapticEvent.selection);
      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'Avatar photo uploaded!');
      }
    } catch (e) {
      state = state.copyWith(isUploading: false);
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to upload photo: $e');
      }
    }
  }

  Future<bool> save(BuildContext context) async {
    final trimmedName = state.name.trim();
    if (trimmedName.isEmpty) {
      AppSnackBar.showError(context, 'Name cannot be empty');
      return false;
    }
    if (trimmedName.length < 2) {
      AppSnackBar.showError(context, 'Name must be at least 2 characters');
      return false;
    }
    if (trimmedName.length > 20) {
      AppSnackBar.showError(context, 'Name cannot exceed 20 characters');
      return false;
    }

    state = state.copyWith(isSaving: true);
    try {
      await ref.read(userRepositoryProvider).updateProfile(
            uid: user.uid,
            name: trimmedName,
            photoUrl: state.removePhoto ? null : state.photoUrl,
            removePhoto: state.removePhoto,
          );
      ref.invalidate(currentUserProvider);

      ref.read(soundServiceProvider).play(AppSound.buttonClick);
      ref.read(hapticServiceProvider).fire(HapticEvent.tap);

      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'Profile updated successfully!');
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      if (context.mounted) {
        AppSnackBar.showError(context, 'Failed to save profile: $e');
      }
      return false;
    }
  }
}

final editProfileProvider = StateNotifierProvider.autoDispose
    .family<EditProfileNotifier, EditProfileState, AppUser>((ref, user) {
  return EditProfileNotifier(ref, user);
});

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key, required this.user});

  final AppUser user;

  static Future<bool?> show(BuildContext context, {required AppUser user}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileDialog(user: user),
    );
  }

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider(widget.user));
    final notifier = ref.read(editProfileProvider(widget.user).notifier);

    final insets = MediaQuery.of(context).viewInsets;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      padding: EdgeInsets.only(bottom: insets.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'EDIT PROFILE',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 20,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurfaceMuted,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.outlineVariant),

          // Content body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: (widget.user.avatarFrameColor == null ||
                                  widget.user.avatarFrameColor!.isEmpty)
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                )
                              : null,
                          child: state.localPhotoBytes != null
                              ? _buildLocalAvatarPreview(
                                  widget.user,
                                  state.localPhotoBytes!,
                                )
                              : UserAvatar(
                                  photoUrl: state.removePhoto
                                      ? null
                                      : state.photoUrl,
                                  name: state.name.isNotEmpty
                                      ? state.name
                                      : widget.user.name,
                                  size: 88,
                                  frameColor: widget.user.avatarFrameColor,
                                ),
                        ),
                        if (state.isUploading)
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Avatar Action Buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: state.isUploading
                            ? null
                            : () => notifier.pickImage(
                                  ImageSource.gallery,
                                  context,
                                ),
                      ),
                      _ActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: state.isUploading
                            ? null
                            : () => notifier.pickImage(
                                  ImageSource.camera,
                                  context,
                                ),
                      ),
                      _ActionButton(
                        icon: Icons.face_retouching_natural_rounded,
                        label: 'Avatars',
                        isActive: state.showPresets,
                        onTap: notifier.togglePresets,
                      ),
                      if (state.photoUrl != null && !state.removePhoto)
                        _ActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Remove',
                          isDanger: true,
                          onTap: notifier.removePhoto,
                        ),
                    ],
                  ),

                  // Preset Avatars Drawer
                  if (state.showPresets) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CHOOSE AN AVATAR',
                                style: GoogleFonts.luckiestGuy(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${kAvatarPresets.length} Styles',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 66,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: kAvatarPresets.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final preset = kAvatarPresets[index];
                                final isSelected = !state.removePhoto &&
                                    state.photoUrl == preset.url;
                                return GestureDetector(
                                  onTap: () => notifier.selectPreset(preset.url),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: UserAvatar(
                                      photoUrl: preset.url,
                                      name: preset.label,
                                      size: 52,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Name Field Section
                  Text(
                    'PLAYER NAME',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 13,
                      color: AppColors.onSurface,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      maxLength: 20,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.badge_rounded,
                          color: AppColors.primary,
                        ),
                        suffixIcon: state.name.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: AppColors.onSurfaceMuted,
                                onPressed: () {
                                  _nameCtrl.clear();
                                  notifier.updateName('');
                                },
                              )
                            : null,
                        hintText: 'Enter player name',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.onSurfaceMuted.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: notifier.updateName,
                    ),
                  ),

                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Visible to all players (2-20 chars)',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                      Text(
                        '${state.name.trim().length}/20',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: state.name.trim().length > 20
                              ? AppColors.danger
                              : AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // Save Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (state.isSaving || state.isUploading)
                          ? null
                          : () async {
                              final success = await notifier.save(context);
                              if (success && context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'SAVE CHANGES',
                                  style: GoogleFonts.luckiestGuy(
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalAvatarPreview(AppUser user, Uint8List bytes) {
    final frame = user.avatarFrameColor == null
        ? null
        : kAvatarFramesByKey[user.avatarFrameColor];
    final shape = frame?.shape ?? FrameShape.circle;
    final hasFrame = frame != null;
    final clipper = ShapeBorderClipper(shape: frameShapeBorder(shape));

    final avatar = ClipPath(
      clipper: clipper,
      child: Image.memory(
        bytes,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 88,
          height: 88,
          decoration: ShapeDecoration(
            color: AppColors.surfaceAlt,
            shape: frameShapeBorder(shape),
          ),
          alignment: Alignment.center,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 35,
            ),
          ),
        ),
      ),
    );

    if (!hasFrame) {
      return SizedBox(width: 88, height: 88, child: avatar);
    }

    const outer = 88 * kFrameScale;
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(outer, outer),
            painter: AvatarFramePainter(frame),
          ),
          avatar,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final fg = isDanger
        ? AppColors.danger
        : (isActive ? AppColors.primary : AppColors.onSurface);
    final bg = isDanger
        ? AppColors.danger.withValues(alpha: 0.1)
        : (isActive
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceContainerLow);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
