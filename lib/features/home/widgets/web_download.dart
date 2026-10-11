// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import '../../../core/services/apk_installer/apk_installer.dart';

void downloadFileWeb(String url) {
  html.window.open(ApkInstaller.playStoreUrl, '_blank');
}

