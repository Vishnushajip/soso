import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/apk_installer/apk_installer.dart';
import 'firebase_providers.dart';

final apkDownloadUrlProvider = StreamProvider<String?>((ref) {
  if (kIsWeb) {
    return Stream.value(ApkInstaller.playStoreUrl);
  }
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('apk').doc('apk').snapshots().map((snap) {
    final url = snap.data()?['apk_url'];
    if (url is String && url.trim().isNotEmpty) return url.trim();
    return null;
  });
});

