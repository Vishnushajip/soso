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
  });

  final String? photoUrl;
  final String? name;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final initial = (name == null || name!.isEmpty) ? '?' : name![0].toUpperCase();

    Widget avatar;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size, height: size, fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(initial),
          placeholder: (_, __) => _fallback(initial),
        ),
      );
    } else {
      avatar = _fallback(initial);
    }

    return SizedBox(
      width: size, height: size,
      child: Stack(
        children: [
          avatar,
          if (online)
            Positioned(
              right: 0, bottom: 0,
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
