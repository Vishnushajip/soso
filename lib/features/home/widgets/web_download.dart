// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

void downloadFileWeb(String url) {
  final anchor = html.AnchorElement(href: url);
  anchor.download = 'soso_arena.apk';
  anchor.target = '_blank';
  anchor.click();
}
