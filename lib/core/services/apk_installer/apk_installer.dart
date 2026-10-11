import 'apk_installer_io.dart'
    if (dart.library.html) 'apk_installer_web.dart' as platform;

/// Thrown when an in-app APK download or install step fails.
class ApkInstallException implements Exception {
  ApkInstallException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Platform-agnostic contract for downloading and installing an APK from inside
/// the app. Only meaningful on Android; on iOS/Web [isSupported] is false and
/// callers should fall back to opening the store/download URL externally.
abstract class ApkInstaller {
  /// Direct Google Play Store testing install link for web users.
  static const String playStoreUrl =
      'https://play.google.com/apps/testing/com.sosarena.app';

  /// Whether in-app download + install is available on this platform.
  bool get isSupported;

  /// Downloads [url] to local storage, reporting progress in the range 0..1.
  /// Returns the saved file path. Throws [ApkInstallException] on failure.
  Future<String> download(
    String url, {
    required void Function(double progress) onProgress,
  });

  /// Launches the system package installer for the APK at [filePath].
  /// Throws [ApkInstallException] if the installer could not be opened.
  Future<void> install(String filePath);
}

/// Builds the correct implementation for the current platform. The actual
/// `dart:io` / plugin code lives only in the IO file, so web builds never
/// reference it.
ApkInstaller buildApkInstaller() => platform.createApkInstaller();
