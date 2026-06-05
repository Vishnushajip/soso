import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../providers/auth_providers.dart';
import '../../../routes/route_names.dart';


final _splashMutedProvider = StateProvider.autoDispose<bool>((ref) => kIsWeb);

final _videoControllerProvider =
    FutureProvider.autoDispose<VideoPlayerController>((ref) async {
      final controller = VideoPlayerController.asset(
        'assets/videos/intro.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await controller.initialize();
      await controller.setVolume(kIsWeb ? 0.0 : 1.0);
      await controller.setLooping(false);

      try {
        await controller.play();
      } catch (e) {
        debugPrint('Autoplay failed: $e');
      }

      ref.onDispose(controller.dispose);
      return controller;
    });

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  VideoPlayerController? _listenedController;
  VoidCallback? _tickListener;

  void _attachCompletionListener(VideoPlayerController controller) {
    if (identical(_listenedController, controller)) return;
    _detachCompletionListener();
    _listenedController = controller;
    _tickListener = () {
      final c = _listenedController;
      if (c == null) return;
      if (c.value.duration > Duration.zero &&
          c.value.position >= c.value.duration) {
        _navigateToNextScreen();
      }
    };
    controller.addListener(_tickListener!);
  }

  void _detachCompletionListener() {
    final c = _listenedController;
    final l = _tickListener;
    if (c != null && l != null) {
      try {
        c.removeListener(l);
      } catch (_) {
        // Controller already disposed by its provider — nothing to remove.
      }
    }
    _listenedController = null;
    _tickListener = null;
  }

  void _navigateToNextScreen() {
    if (_navigated || !mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth.isLoading) return;
    _navigated = true;
    final loggedIn = auth.valueOrNull != null;
    context.go(loggedIn ? RouteNames.home : RouteNames.signIn);
  }

  Future<void> _handleTap() async {
    final muted = ref.read(_splashMutedProvider);
    if (muted) {
      final controller = ref.read(_videoControllerProvider).valueOrNull;
      if (controller != null) {
        ref.read(_splashMutedProvider.notifier).state = false;
        await controller.setVolume(1.0);
        await controller.seekTo(Duration.zero);
        await controller.play();
        return;
      }
    }
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _detachCompletionListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(_videoControllerProvider);
    final muted = ref.watch(_splashMutedProvider);

    ref.listen<AsyncValue<VideoPlayerController>>(_videoControllerProvider, (
      _,
      next,
    ) {
      next.whenData(_attachCompletionListener);
    });

    return GestureDetector(
      onTap: _handleTap,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (muted)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.volume_off_rounded,
                            size: 16,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap for sound',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white38,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Tap to continue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white38,
                          letterSpacing: 2.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
