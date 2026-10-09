import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  friendRequest,
  friendAccepted,
  message,
  matchInvite,
  matchStarted,
  rankUp,
  reward,
  generic,
}

class AppNotification {
  final String id;
  final String toUid;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.toUid,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppNotification(
      id: doc.id,
      toUid: (d['toUid'] as String?) ?? '',
      type: AppNotificationType.values.firstWhere(
        (t) => t.name == (d['type'] as String?),
        orElse: () => AppNotificationType.generic,
      ),
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      data: Map<String, dynamic>.from(d['data'] as Map? ?? const {}),
      read: (d['read'] as bool?) ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
