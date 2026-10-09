import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_providers.dart';

final apkDownloadUrlProvider = StreamProvider<String?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('apk').doc('apk').snapshots().map((snap) {
    final url = snap.data()?['apk_url'];
    if (url is String && url.trim().isNotEmpty) return url.trim();
    return null;
  });
});
