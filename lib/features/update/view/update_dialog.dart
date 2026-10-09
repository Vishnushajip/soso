import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/app_update_providers.dart';
import '../../../core/routes/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate> {
  bool _shown = false;

  bool get _shouldShowUpdateDialog {
    if (!kIsWeb) return true;

    final userAgent = html.window.navigator.userAgent.toLowerCase();

    return userAgent.contains('android');
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShow(ref.read(appUpdateDecisionProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateDecision?>(
      appUpdateDecisionProvider,
      (_, next) => _maybeShow(next),
    );

    return widget.child;
  }

  void _maybeShow(UpdateDecision? decision) {
    if (!_shouldShowUpdateDialog) return;

    if (_shown) return;
    if (decision == null) return;
    if (!decision.shouldPrompt) return;

    _shown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;

      if (ctx == null) {
        _shown = false;
        return;
      }

      showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(decision: decision),
      );
    });
  }
}

class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key, required this.decision});
  final UpdateDecision decision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forced = decision.isForced;
    final config = decision.config;
    final busy = ref.watch(
      apkDownloadControllerProvider.select((s) => s.isBusy),
    );

    return PopScope(
      canPop: !forced && !busy,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.sColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  forced
                      ? Icons.system_update_rounded
                      : Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                forced ? 'Update Required' : 'Update Available',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: AppColors.onSurface,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                config.updateMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 14),
              _VersionRow(
                current: decision.currentVersion,
                latest: config.latestVersion,
              ),
              const SizedBox(height: 20),
              _Actions(decision: decision),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.decision});
  final UpdateDecision decision;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forced = decision.isForced;
    final canInstallInApp = ref.watch(apkInstallerProvider).isSupported;
    final download = ref.watch(apkDownloadControllerProvider);

    if (canInstallInApp && download.status == ApkDownloadStatus.downloading) {
      return _ProgressView(
        label: 'Downloading update',

        progress: download.progress > 0 ? download.progress : null,
      );
    }
    if (canInstallInApp && download.status == ApkDownloadStatus.installing) {
      return const _ProgressView(label: 'Opening installer…', progress: null);
    }

    final isError = download.status == ApkDownloadStatus.error;
    final isDone = download.status == ApkDownloadStatus.done;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canInstallInApp && isError)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              download.error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        AppButton(
          icon: isDone ? Icons.install_mobile_rounded : Icons.download_rounded,
          label: isDone
              ? 'Install again'
              : isError
              ? 'Retry'
              : forced
              ? 'Update Now'
              : 'Update',
          expanded: true,
          onPressed: () => _start(context, ref, canInstallInApp),
        ),
        if (!forced) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              isDone ? 'Close' : 'Maybe later',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, bool inApp) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = ref.read(updateDownloadUrlProvider);
    if (url == null || url.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No download link available')),
      );
      return;
    }
    if (inApp) {
      await ref
          .read(apkDownloadControllerProvider.notifier)
          .downloadAndInstall(url);
    } else {
      final ok = await ref.read(appUpdateServiceProvider).launchUpdate(url);
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the update link')),
        );
      }
    }
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.label, required this.progress});
  final String label;

  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          progress == null ? label : '$label  ${(progress! * 100).round()}%',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.current, required this.latest});
  final String current;
  final String latest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.14),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _VersionChip(
            label: 'Current',
            value: current.isEmpty ? '—' : current,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          _VersionChip(
            label: 'Latest',
            value: latest.isEmpty ? '—' : latest,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.luckiestGuy(
            fontSize: 15,
            letterSpacing: 0.4,
            color: highlight ? AppColors.primary : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
