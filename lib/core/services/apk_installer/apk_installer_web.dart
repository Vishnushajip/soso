// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'apk_installer.dart';

ApkInstaller createApkInstaller() => WebApkInstaller();

/// Web implementation: instead of downloading or installing an APK file,
/// uses the direct Play Store testing install link.
class WebApkInstaller implements ApkInstaller {
  static const String playStoreUrl = ApkInstaller.playStoreUrl;

  @override
  bool get isSupported => true;

  @override
  Future<String> download(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    onProgress(1.0);
    return playStoreUrl;
  }

  @override
  Future<void> install(String filePath) async {
    final targetUrl = (filePath.isNotEmpty && filePath.startsWith('http'))
        ? filePath
        : playStoreUrl;
    html.window.open(targetUrl, '_blank');
  }
}

