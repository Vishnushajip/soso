import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';
import '../services/app_update_service.dart';
import '../models/app_version_config.dart';
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

/// Updates are always delivered through Google Play (Play policy forbids
/// self-updating outside Play), so the target is the store listing.
final updateDownloadUrlProvider = Provider<String?>(
  (ref) => AppConstants.playStoreUrl,
);

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


