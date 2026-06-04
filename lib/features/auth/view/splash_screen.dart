import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../providers/auth_providers.dart';
import '../../../routes/route_names.dart';

final _videoControllerProvider =
    FutureProvider.autoDispose<VideoPlayerController>((ref) async {
      final controller = VideoPlayerController.asset(
        'assets/videos/intro.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      // Browsers block autoplay for videos with sound. We must mute it on Web.
      await controller.setVolume(kIsWeb ? 0.0 : 1.0);
      await controller.setLooping(false);
      
      try {
        await controller.play();
      } catch (e) {
        // Autoplay might still be rejected by strict browser settings
        debugPrint('Autoplay failed: $e');
      }

      ref.onDispose(controller.dispose);
      return controller;
    });

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _navigateToNextScreen(WidgetRef ref, BuildContext context) {
    final auth = ref.read(authStateProvider);
    if (auth.isLoading) return;
    final loggedIn = auth.valueOrNull != null;
    context.go(loggedIn ? RouteNames.home : RouteNames.signIn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoAsync = ref.watch(_videoControllerProvider);

    ref.listen<AsyncValue<VideoPlayerController>>(_videoControllerProvider, (
      _,
      next,
    ) {
      next.whenData((controller) {
        controller.addListener(() {
          if (controller.value.position >= controller.value.duration &&
              controller.value.duration > Duration.zero) {
            _navigateToNextScreen(ref, context);
          }
        });
      });
    });

    return GestureDetector(
      onTap: () => _navigateToNextScreen(ref, context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            videoAsync.when(
              data: (controller) => SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (_, value, child) =>
                    Opacity(opacity: value, child: child),
                child: Text(
                  'Tap to continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white38,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
