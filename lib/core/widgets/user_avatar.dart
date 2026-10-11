import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../customization/avatar_frame.dart';
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
    final initial = (name == null || name!.isEmpty)
        ? '?'
        : name![0].toUpperCase();

    final frame = frameColor == null ? null : kAvatarFramesByKey[frameColor];
    final shape = frame?.shape ?? FrameShape.circle;
    final hasFrame = frame != null;

    final clipper = ShapeBorderClipper(shape: frameShapeBorder(shape));

    Widget avatar;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (photoUrl!.startsWith('data:')) {
        final commaIdx = photoUrl!.indexOf(',');
        final base64Data = commaIdx != -1
            ? photoUrl!.substring(commaIdx + 1)
            : photoUrl!;
        try {
          final cleanBase64 = base64Data.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(cleanBase64);
          avatar = ClipPath(
            clipper: clipper,
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _fallback(initial, shape),
            ),
          );
        } catch (_) {
          avatar = ClipPath(clipper: clipper, child: _fallback(initial, shape));
        }
      } else if (kIsWeb) {
        final webUrl = photoUrl!.contains('firebasestorage.googleapis.com')
            ? 'https://wsrv.nl/?url=${Uri.encodeComponent(photoUrl!)}'
            : photoUrl!;
        avatar = ClipPath(
          clipper: clipper,
          child: Image.network(
            webUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _fallback(initial, shape),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _fallback(initial, shape);
            },
          ),
        );
      } else {
        final decodePx = (size * 3).round();
        avatar = ClipPath(
          clipper: clipper,
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: decodePx,
            memCacheHeight: decodePx,
            errorWidget: (context, url, error) => _fallback(initial, shape),
            placeholder: (context, url) => _fallback(initial, shape),
          ),
        );
      }
    } else {
      avatar = ClipPath(clipper: clipper, child: _fallback(initial, shape));
    }

    if (!hasFrame) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [avatar, if (online) _onlineDot(0, 0)],
        ),
      );
    }

    final outer = size * kFrameScale;
    final inset = (outer - size) / 2;
    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(outer, outer),
            painter: AvatarFramePainter(frame),
          ),
          avatar,
          if (online) _onlineDot(inset + size * 0.02, inset + size * 0.02),
        ],
      ),
    );
  }

  Widget _onlineDot(double right, double bottom) => Positioned(
    right: right,
    bottom: bottom,
    child: Container(
      width: size * 0.28,
      height: size * 0.28,
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.bg, width: 2),
      ),
    ),
  );

  Widget _fallback(String initial, FrameShape shape) => Container(
    width: size,
    height: size,
    decoration: ShapeDecoration(
      color: AppColors.surfaceAlt,
      shape: frameShapeBorder(shape),
    ),
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
