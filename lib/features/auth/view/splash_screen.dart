import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../providers/auth_providers.dart';
import '../../../routes/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _navigationTriggered = false;
  bool _videoCompleted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
      await _controller!.initialize();
      if (!mounted) return;
      
      setState(() => _initialized = true);
      _controller!.play();
      _controller!.addListener(_checkVideoEnd);
    } catch (_) {
      _fallbackNavigation();
    }
  }

  void _fallbackNavigation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAndNavigate();
      }
    });
  }

  void _checkVideoEnd() {
    if (!mounted || _controller == null) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    if (dur > Duration.zero && pos >= dur) {
      _videoCompleted = true;
      _checkAndNavigate();
    }
  }

  void _checkAndNavigate() {
    if (_navigationTriggered) return;
    final isReady = _videoCompleted || !_initialized;
    if (!isReady) return;

    final auth = ref.read(authStateProvider);
    if (auth.isLoading) return;
    
    _navigationTriggered = true;
    final target = auth.valueOrNull != null ? RouteNames.home : RouteNames.signIn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(target);
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkVideoEnd);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Object?>>(
      authStateProvider,
      (_, next) {
        if (!next.isLoading) {
          _checkAndNavigate();
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SOS',
                  style: GoogleFonts.outfit(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sColor,
                    letterSpacing: 6,
                  ),
                ),
                Text(
                  'ARENA',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: AppColors.onSurfaceMuted,
                    letterSpacing: 12,
                  ),
                ),
                const SizedBox(height: 36),
                const AppLoader(label: 'Warming up the board…'),
              ],
            ),
          ),

          if (_controller != null && _initialized)
            AnimatedOpacity(
              opacity: _initialized ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
