import 'apk_installer.dart';

ApkInstaller createApkInstaller() => WebApkInstaller();

/// Web stub: APKs cannot be downloaded/installed in a browser. Callers check
/// [isSupported] and fall back to launching the download URL externally.
class WebApkInstaller implements ApkInstaller {
  @override
  bool get isSupported => false;

  @override
  Future<String> download(
    String url, {
    required void Function(double progress) onProgress,
  }) =>
      throw ApkInstallException('In-app APK install is not available on web.');

  @override
  Future<void> install(String filePath) =>
      throw ApkInstallException('In-app APK install is not available on web.');
}
