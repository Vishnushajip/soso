import 'package:url_launcher/url_launcher.dart';

import '../../models/app_version_config.dart';
import '../utils/version_utils.dart';

enum UpdateStatus { upToDate, optional, forced }

class UpdateDecision {
  const UpdateDecision({
    required this.status,
    required this.config,
    required this.currentVersion,
  });

  final UpdateStatus status;
  final AppVersionConfig config;
  final String currentVersion;

  bool get shouldPrompt => status != UpdateStatus.upToDate;
  bool get isForced => status == UpdateStatus.forced;
}

class AppUpdateService {
  const AppUpdateService();

  UpdateStatus evaluate({
    required String currentVersion,
    required AppVersionConfig config,
  }) {
    if (currentVersion.trim().isEmpty) return UpdateStatus.upToDate;

    if (config.minimumVersion.isNotEmpty &&
        VersionUtils.isLower(currentVersion, config.minimumVersion)) {
      return UpdateStatus.forced;
    }
    if (config.latestVersion.isNotEmpty &&
        VersionUtils.isHigher(config.latestVersion, currentVersion)) {
      return UpdateStatus.optional;
    }
    return UpdateStatus.upToDate;
  }


  Future<bool> launchUpdate(String? url) async {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
