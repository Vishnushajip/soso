import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mobile_video_splash.dart';
import 'web_reveal_splash.dart';

/// Web gets the animated logo reveal; Android/iOS keep the video intro.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      kIsWeb ? const WebRevealSplash() : const MobileVideoSplash();
}
