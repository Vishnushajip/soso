import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:new_version_plus/new_version_plus.dart';

import '../routes/app_router.dart';

/// Google Play In-App Updates (Android only).
///
/// * Cold start → asks Play for an update. If one exists, the full-screen
///   **immediate** flow runs (Play downloads + installs + restarts the app).
///   If Play only allows a **flexible** update, it downloads in the background
///   and is installed automatically as soon as the download finishes.
/// * App resume → resumes an immediate update the user backed out of, or
///   installs a flexible update that finished downloading.
/// * Play API unavailable (e.g. sideloaded / debug build) → falls back to a
///   store-version check that offers a "go to Play Store" dialog.
///
/// Note: Play requires the user to confirm an update; no app can install
/// itself silently. Users with Play auto-update enabled get it in the
/// background anyway.
class InAppUpdateService with WidgetsBindingObserver {
  InAppUpdateService._internal();
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;

  static const _packageName = 'com.sosarena.app';

  bool _observing = false;
  bool _checking = false;
  bool _flexibleRunning = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks Play for an update and starts it. Safe to call repeatedly.
  Future<void> checkForUpdate() async {
    if (!_supported || _checking) return;
    _startObserving();
    _checking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      await _handle(info);
    } catch (e) {
      debugPrint('Play in-app update unavailable: $e');
      await _checkViaStoreListing();
    } finally {
      _checking = false;
    }
  }

  /// Starts the immediate Play update flow on demand (e.g. from the update
  /// dialog). Returns false if Play has no update to offer or the API failed,
  /// so the caller can fall back to opening the store listing.
  Future<bool> startImmediateUpdate() async {
    if (!_supported) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      final available =
          info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress;
      if (!available || !info.immediateUpdateAllowed) return false;
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      debugPrint('Immediate update failed: $e');
      return false;
    }
  }

  Future<void> _handle(AppUpdateInfo info) async {
    // A flexible update already downloaded → install it now.
    if (info.installStatus == InstallStatus.downloaded) {
      await InAppUpdate.completeFlexibleUpdate();
      return;
    }

    switch (info.updateAvailability) {
      case UpdateAvailability.developerTriggeredUpdateInProgress:
        // User left an immediate update mid-way — Play requires resuming it.
        await InAppUpdate.performImmediateUpdate();
      case UpdateAvailability.updateAvailable:
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed && !_flexibleRunning) {
          _flexibleRunning = true;
          try {
            final result = await InAppUpdate.startFlexibleUpdate();
            if (result == AppUpdateResult.success) {
              await InAppUpdate.completeFlexibleUpdate();
            }
          } finally {
            _flexibleRunning = false;
          }
        }
      default:
        break;
    }
  }

  void _startObserving() {
    if (_observing) return;
    _observing = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkForUpdate();
  }

  /// Fallback for installs that can't talk to the Play update API.
  Future<void> _checkViaStoreListing() async {
    final newVersion = NewVersionPlus(androidId: _packageName);
    try {
      final status = await newVersion.getVersionStatus();
      if (status == null || !status.canUpdate) return;

      // Use the root navigator so this works no matter which screen
      // (splash, sign-in, home) is showing when the check completes.
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      newVersion.showUpdateDialog(
        context: ctx,
        versionStatus: status,
        allowDismissal: true,
        dialogTitle: 'Update Available',
        dialogText:
            'A new version (${status.storeVersion}) is available on Google '
            'Play.\n\nYou\'re currently on version ${status.localVersion}.',
        updateButtonText: 'Update Now',
        dismissButtonText: 'Later',
      );
    } catch (e) {
      debugPrint('Store-listing update check failed: $e');
    }
  }
}
