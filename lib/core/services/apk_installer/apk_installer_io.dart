import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'apk_installer.dart';

ApkInstaller createApkInstaller() => IoApkInstaller();

/// Native implementation. In-app download + install is supported on Android
/// only; iOS apps cannot side-load APKs.
class IoApkInstaller implements ApkInstaller {
  final Dio _dio = Dio();

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<String> download(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    if (url.trim().isEmpty) {
      throw ApkInstallException('No download link is configured.');
    }
    // App-specific external dir needs no storage permission and is covered by
    // open_filex's bundled FileProvider, so the installer can read the file.
    final baseDir =
        await getExternalStorageDirectory() ?? await getTemporaryDirectory();
    final savePath = '${baseDir.path}/sos_arena_update.apk';

    final existing = File(savePath);
    if (await existing.exists()) {
      await existing.delete();
    }

    try {
      await _dio.download(
        url.trim(),
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );
    } on DioException catch (e) {
      throw ApkInstallException('Download failed: ${e.message ?? e.type.name}');
    } catch (e) {
      throw ApkInstallException('Download failed: $e');
    }
    return savePath;
  }

  @override
  Future<void> install(String filePath) async {
    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw ApkInstallException(
        result.message.isEmpty ? 'Could not open installer.' : result.message,
      );
    }
  }
}
