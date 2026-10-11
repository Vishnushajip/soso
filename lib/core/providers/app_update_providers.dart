import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/apk_installer/apk_installer.dart';
import '../services/app_update_service.dart';
import '../models/app_version_config.dart';
import 'app_download_providers.dart';
import 'firebase_providers.dart';


final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

final appVersionProvider = Provider<String>(
  (ref) => ref.watch(packageInfoProvider).valueOrNull?.version ?? '',
);

final appVersionLabelProvider = Provider<String>((ref) {
  final info = ref.watch(packageInfoProvider).valueOrNull;
  if (info == null) return '';
  final build = info.buildNumber.trim();
  return build.isEmpty ? info.version : '${info.version} ($build)';
});

final appVersionConfigProvider = StreamProvider<AppVersionConfig?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('app_config')
      .doc('version')
      .snapshots()
      .map(
        (snap) => snap.exists ? AppVersionConfig.fromMap(snap.data()) : null,
      );
});

final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => const AppUpdateService(),
);

final updateDownloadUrlProvider = Provider<String?>((ref) {
  if (kIsWeb) {
    return ApkInstaller.playStoreUrl;
  }
  final configUrl = ref.watch(appVersionConfigProvider).valueOrNull?.apkUrl;
  if (configUrl != null && configUrl.isNotEmpty) return configUrl;
  return ref.watch(apkDownloadUrlProvider).valueOrNull;
});

final appUpdateDecisionProvider = Provider<UpdateDecision?>((ref) {
  final pkg = ref.watch(packageInfoProvider).valueOrNull;
  final config = ref.watch(appVersionConfigProvider).valueOrNull;
  if (pkg == null || config == null) return null;

  final status = ref
      .watch(appUpdateServiceProvider)
      .evaluate(currentVersion: pkg.version, config: config);
  return UpdateDecision(
    status: status,
    config: config,
    currentVersion: pkg.version,
  );
});


final apkInstallerProvider = Provider<ApkInstaller>((ref) => buildApkInstaller());

enum ApkDownloadStatus { idle, downloading, installing, done, error }

class ApkDownloadState {
  const ApkDownloadState({
    this.status = ApkDownloadStatus.idle,
    this.progress = 0,
    this.error,
  });

  final ApkDownloadStatus status;

  final double progress;
  final String? error;

  bool get isBusy =>
      status == ApkDownloadStatus.downloading ||
      status == ApkDownloadStatus.installing;

  ApkDownloadState copyWith({
    ApkDownloadStatus? status,
    double? progress,
    String? error,
  }) =>
      ApkDownloadState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        error: error,
      );
}


class ApkDownloadController extends Notifier<ApkDownloadState> {
  @override
  ApkDownloadState build() => const ApkDownloadState();

  Future<void> downloadAndInstall(String? url) async {
    if (state.isBusy) return;
    final installer = ref.read(apkInstallerProvider);
    if (!installer.isSupported) {
      state = const ApkDownloadState(
        status: ApkDownloadStatus.error,
        error: 'In-app install is only available on Android.',
      );
      return;
    }

    state = const ApkDownloadState(
      status: ApkDownloadStatus.downloading,
      progress: 0,
    );
    try {
      final path = await installer.download(
        url ?? '',
        onProgress: (p) => state = state.copyWith(
          status: ApkDownloadStatus.downloading,
          progress: p.clamp(0.0, 1.0),
        ),
      );
      state = state.copyWith(
        status: ApkDownloadStatus.installing,
        progress: 1,
      );
      await installer.install(path);
      state = state.copyWith(status: ApkDownloadStatus.done);
    } catch (e) {
      state = ApkDownloadState(
        status: ApkDownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const ApkDownloadState();
}

final apkDownloadControllerProvider =
    NotifierProvider<ApkDownloadController, ApkDownloadState>(
  ApkDownloadController.new,
);
