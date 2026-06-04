import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'web_download_stub.dart' if (dart.library.html) 'web_download.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/app_download_providers.dart';

class DownloadAppBanner extends ConsumerStatefulWidget {
  const DownloadAppBanner({super.key});

  @override
  ConsumerState<DownloadAppBanner> createState() => _DownloadAppBannerState();
}

class _DownloadAppBannerState extends ConsumerState<DownloadAppBanner> {
  bool _isPressed = false;
  bool _launching = false;

  Future<void> _download(String url) async {
    if (_launching) return;
    setState(() => _launching = true);
    HapticFeedback.lightImpact();

    final uri = Uri.tryParse(url);
    var ok = false;
    
    try {
      if (uri != null) {
        if (kIsWeb) {
          downloadFileWeb(url);
          ok = true;
        } else {
          ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      ok = false;
    } finally {
      if (mounted) {
        setState(() => _launching = false);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text(
                "Couldn't open the download link. Please try again.",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = ref.watch(apkDownloadUrlProvider).valueOrNull;
    if (url == null) return const SizedBox.shrink();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _download(url),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.android_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Get the App',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'APK',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download SOS Arena and play anywhere, anytime.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: _launching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
