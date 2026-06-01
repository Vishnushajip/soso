import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.size = 40,
    this.online = false,
    this.frameColor,
  });

  final String? photoUrl;
  final String? name;
  final double size;
  final bool online;
  final String? frameColor;

  @override
  Widget build(BuildContext context) {
    final initial = (name == null || name!.isEmpty) ? '?' : name![0].toUpperCase();

    Color? borderColor;
    if (frameColor == 'gold') {
      borderColor = const Color(0xFFFD9D06);
    } else if (frameColor == 'neon_blue') {
      borderColor = const Color(0xFF3B82F6);
    } else if (frameColor == 'vibrant_green') {
      borderColor = const Color(0xFF10B981);
    }

    Widget avatar;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size, height: size, fit: BoxFit.cover,
          errorWidget: (context, url, error) => _fallback(initial),
          placeholder: (context, url) => _fallback(initial),
        ),
      );
    } else {
      avatar = _fallback(initial);
    }

    if (borderColor != null) {
      avatar = Container(
        padding: EdgeInsets.all(size * 0.05), // inner spacing for the frame ring
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: size * 0.06),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: avatar,
      );
    }

    return SizedBox(
      width: borderColor != null ? size * 1.22 : size,
      height: borderColor != null ? size * 1.22 : size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (online)
            Positioned(
              right: borderColor != null ? size * 0.05 : 0,
              bottom: borderColor != null ? size * 0.05 : 0,
              child: Container(
                width: size * 0.28, height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(String initial) => Container(
        width: size, height: size,
        decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.4,
          ),
        ),
      );
}
