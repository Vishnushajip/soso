import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/providers/auth_providers.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';

/// Web splash controller.
///
/// The logo-reveal animation itself lives in `web/index.html` (pure HTML/CSS),
/// so it starts the instant the page opens instead of waiting several seconds
/// for the Flutter bundle to download. This route sits underneath that overlay,
/// waits for auth to resolve, then:
///   1. dispatches `sos-splash-done` → the overlay finishes its reveal and
///      zooms out,
///   2. navigates to home / sign-in, which the zoom-out reveals.
class WebRevealSplash extends ConsumerStatefulWidget {
  const WebRevealSplash({super.key});

  @override
  ConsumerState<WebRevealSplash> createState() => _WebRevealSplashState();
}

class _WebRevealSplashState extends ConsumerState<WebRevealSplash> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Tell the HTML overlay a splash route is active, so it waits for us
    // instead of exiting on Flutter's first frame.
    html.window.dispatchEvent(html.Event('sos-splash-mounted'));
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());
  }

  void _tryNavigate() {
    if (_navigated || !mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth.isLoading) return;
    _navigated = true;

    html.window.dispatchEvent(html.Event('sos-splash-done'));
    context.go(auth.valueOrNull != null ? RouteNames.home : RouteNames.signIn);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (!next.isLoading) _tryNavigate();
    });

    // Matches the overlay's backdrop so nothing flashes if it fades early.
    return const Scaffold(
      backgroundColor: AppColors.arenaBgBottom,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.arenaBgTop, AppColors.arenaBgBottom],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}
