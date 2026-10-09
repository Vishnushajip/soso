import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();

  factory InAppUpdateService() => _instance;

  InAppUpdateService._internal();

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await _checkForManualUpdate(context);
      }
    } catch (e) {
      debugPrint("Error checking for update: $e");
      await _checkForManualUpdate(context);
    }
  }

  Future<void> _checkForManualUpdate(BuildContext context) async {
    final newVersion = NewVersionPlus(
      androidId: "com.sosarena.app",
    );

    try {
      final status = await newVersion.getVersionStatus();

      if (status != null && status.canUpdate) {
        newVersion.showUpdateDialog(
          allowDismissal: false,
          context: context,
          versionStatus: status,
          dialogTitle: "Update Available",
          dialogText:
              "A new version (${status.storeVersion}) is available!\n\nYou're currently on version ${status.localVersion}.",
          updateButtonText: "Update Now",
          dismissButtonText: "Later",
        );
      }
    } catch (e) {
      debugPrint("Error checking for app update: $e");
    }
  }
}
